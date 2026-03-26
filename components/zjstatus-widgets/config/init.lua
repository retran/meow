-- MIT License
--
-- Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @file: components/zjstatus-widgets/config/init.lua
-- @brief: Event-driven zjstatus pipe widgets for zellij via Hammerspoon.
--         Pushes keyboard layout, Wi-Fi SSID, battery, CPU, memory, and
--         weather to all active zellij sessions without polling or spawning
--         child processes for the fast-changing widgets.
-- @author: Andrew Vasilyev
-- @license: MIT
--
-- Architecture:
--   Hammerspoon is a signed macOS application with Location Services access,
--   so it can read the Wi-Fi SSID (unlike unsigned CLI daemons).
--
--   Each widget uses the most appropriate update mechanism:
--     keyboard  — hs.keycodes.inputSourceChanged (instant, zero-cost)
--     network   — hs.wifi.watcher (instant, zero-cost)
--     battery   — hs.battery.watcher (instant, zero-cost)
--     cpu       — hs.host.cpuUsage(interval, callback) non-blocking two-sample API
--     memory    — hs.timer every 10 s, hs.host.vmStat (no spawn)
--     weather   — hs.timer every 30 min, hs.http.asyncGet (no curl spawn)
--
--   Session discovery runs asynchronously via hs.task every SESSION_INTERVAL_S
--   seconds and on every URL-handler trigger.  Event-driven callbacks (keyboard,
--   battery, network) pipe directly to the cached session list — no blocking
--   shell call on the hot path.
--
--   On every update, the new value is sent to ALL active zellij sessions via:
--     zellij --session <name> pipe "zjstatus::pipe::pipe_<widget>::<value>"
--   Session names are validated before use. The zellij binary path is
--   resolved once at startup and never re-evaluated.
--
-- New-session bootstrap:
--   When a new zellij session starts, fish conf.d calls:
--     open "hammerspoon://zjstatus-push-all"
--   Hammerspoon re-sends all cached widget values immediately and again after
--   4 s (to survive zjstatus's own startup latency).
--
-- Log file: ~/.local/share/zjstatus-widgets/zjstatus-widgets.log (rotates at 256 KiB)

local M = {}

-- ── Logging ────────────────────────────────────────────────────────────────
local LOG_FILE = os.getenv("HOME") .. "/.local/share/zjstatus-widgets/zjstatus-widgets.log"
local LOG_MAX  = 256 * 1024  -- rotate at 256 KiB

local function log(msg)
    -- Lazy-create the log directory
    os.execute("mkdir -p '" .. LOG_FILE:match("^(.*)/") .. "'")
    local f = io.open(LOG_FILE, "a")
    if not f then return end
    f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. msg .. "\n")
    -- Cheap size check: rotate by truncating when too large
    local size = f:seek("end")
    f:close()
    if size and size > LOG_MAX then
        -- Keep the tail: read last half, rewrite
        local rf = io.open(LOG_FILE, "r")
        if rf then
            rf:seek("set", math.floor(size / 2))
            local tail = rf:read("*a")
            rf:close()
            local wf = io.open(LOG_FILE, "w")
            if wf then wf:write(tail); wf:close() end
        end
    end
end

-- ── Constants ──────────────────────────────────────────────────────────────

local CPU_INTERVAL_S           = 5
local MEM_INTERVAL_S           = 10
local SESSION_INTERVAL_S       = 10    -- async session list refresh cadence (fallback only)

-- Theme-aware palette colors.
-- Defaults are Catppuccin Mocha; overwritten at startup and on theme change
-- by loadColors() which reads ~/.local/share/zjstatus-widgets/colors.lua.
local C_GREEN  = "#a6e3a1"
local C_YELLOW = "#f9e2af"
local C_ORANGE = "#fab387"
local C_RED    = "#f38ba8"
local C_MAUVE  = "#cba6f7"
local C_BLUE   = "#89b4fa"
local C_BG     = "#1e1e2e"

local COLORS_FILE = os.getenv("HOME") .. "/.local/share/zjstatus-widgets/colors.lua"

-- Load colors from the generated Lua file written by apply-theme-zellij.
-- Returns true if colors were updated, false otherwise.
local function loadColors()
    local f = io.open(COLORS_FILE, "r")
    if not f then return false end
    f:close()
    local ok, palette = pcall(dofile, COLORS_FILE)
    if not ok or type(palette) ~= "table" then
        log("loadColors: failed to parse " .. COLORS_FILE .. ": " .. tostring(palette))
        return false
    end
    C_BG     = palette.bg     or C_BG
    C_GREEN  = palette.green  or C_GREEN
    C_YELLOW = palette.yellow or C_YELLOW
    C_ORANGE = palette.orange or C_ORANGE
    C_RED    = palette.red    or C_RED
    C_MAUVE  = palette.mauve  or C_MAUVE
    C_BLUE   = palette.blue   or C_BLUE
    log("loadColors: bg=" .. C_BG .. " green=" .. C_GREEN .. " blue=" .. C_BLUE)
    return true
end

local function colored(fg, text)
    return "#[fg=" .. fg .. ",bg=" .. C_BG .. "]" .. text
end

-- Battery discharge icons (0%..100% in 10% steps, index 1..11)
local ICONS_DISCHARGING = {
    "󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"
}

-- ── Internal state ─────────────────────────────────────────────────────────

local zellijBin        = nil   -- absolute path, resolved once
local lastValues       = {}    -- widget -> last pushed string (for re-send)
local cachedSessions   = {}    -- list of validated session name strings

-- Watchers / timers — kept in M so cleanup() can stop them
M._wifiWatcher      = nil
M._batteryWatcher   = nil
M._memTimer         = nil
M._focusTimer       = nil
M._sessionTimer     = nil
M._dateTimer        = nil
M._timeTimer        = nil
M._reachWatcher     = nil
M._focusWatcher     = nil
M._colorsWatcher    = nil

-- ── Zellij session discovery & piping ──────────────────────────────────────

-- Validate a zellij session name: only word chars and hyphens.
local function isValidSessionName(name)
    return type(name) == "string" and name:match("^[%w%-]+$") ~= nil
end

-- Resolve the zellij binary once.
-- hs.execute runs in a restricted GUI PATH, so we probe known locations directly.
-- Never call a login shell here — it can hang during HS startup.
local function resolveZellij()
    local candidates = {
        "/opt/homebrew/bin/zellij",   -- Apple Silicon Homebrew
        "/usr/local/bin/zellij",      -- Intel Homebrew
        "/usr/bin/zellij",
        "/nix/var/nix/profiles/default/bin/zellij",
    }
    for _, p in ipairs(candidates) do
        local f = io.open(p, "r")
        if f then f:close(); return p end
    end
    return nil
end

-- Parse session names out of `zellij list-sessions --no-formatting` output.
local function parseSessions(output)
    local result = {}
    for line in output:gmatch("[^\n]+") do
        local name = line:match("^([%w%-]+)")
        if name and isValidSessionName(name) then
            result[#result + 1] = name
        end
    end
    return result
end

-- Refresh the session cache asynchronously (fallback/startup only).
-- Calls optional callback(sessions) when done.
-- Never wipes the cache if list-sessions returns nothing — a transient empty
-- result (e.g. during session startup) would drop all sessions and stop all
-- widget pushes until the next refresh cycle.
local function refreshSessions(callback)
    if not zellijBin then return end
    hs.task.new(zellijBin, function(code, out, _)
        if code == 0 and out then
            local fresh = parseSessions(out)
            if #fresh > 0 then
                cachedSessions = fresh
            end
        end
        if callback then callback(cachedSessions) end
    end, {"list-sessions", "--no-formatting"}):start()
end

-- Register a session name in the cache (idempotent).
local function registerSession(name)
    if not isValidSessionName(name) then return end
    for _, s in ipairs(cachedSessions) do
        if s == name then return end  -- already present
    end
    cachedSessions[#cachedSessions + 1] = name
end

-- Send a widget value to a specific session (fire-and-forget).
local function pipeToSession(sessionName, widget, value)
    if not zellijBin then return end
    local payload = "zjstatus::pipe::pipe_" .. widget .. "::" .. value
    hs.task.new(zellijBin, function(code, _, err)
        -- Prune session from cache if zellij says it no longer exists
        if code ~= 0 and err and err:find("not found") then
            for i, s in ipairs(cachedSessions) do
                if s == sessionName then
                    table.remove(cachedSessions, i)
                    break
                end
            end
        end
    end, {
        "--session", sessionName,
        "pipe", payload
    }):start()
end

-- Push a widget value to all sessions in the cache.
local function pushCached(widget, value)
    if not zellijBin then return end
    log("pushCached [" .. widget .. "] = " .. tostring(value) .. " (sessions=" .. #cachedSessions .. ")")
    lastValues[widget] = value
    for _, name in ipairs(cachedSessions) do
        pipeToSession(name, widget, value)
    end
end

-- Re-send all last known values to all sessions in the cache.
local function pushAll()
    for widget, value in pairs(lastValues) do
        for _, name in ipairs(cachedSessions) do
            pipeToSession(name, widget, value)
        end
    end
end

-- Push all values to a single named session.
local function pushToSession(name)
    if not isValidSessionName(name) then return end
    for widget, value in pairs(lastValues) do
        pipeToSession(name, widget, value)
    end
end

-- ── Keyboard layout ────────────────────────────────────────────────────────

local function keyboardLabel()
    local src = hs.keycodes.currentSourceID()
    log("keyboard src=" .. tostring(src))
    if not src then return colored(C_BLUE, "󰌌 ?") end
    local name = src
        :gsub("^com%.apple%.keylayout%.", "")
        :gsub("^com%.apple%.inputmethod%.", "")
    name = name:match("%.([^%.]+)$") or name
    if name == "ABC" or name == "US"
            or name:find("^USInternational") or name:find("^British")
            or name:find("^Australian") then
        return colored(C_BLUE, "󰌌 EN")
    elseif name:find("^Russian") then
        return colored(C_BLUE, "󰌌 RU")
    else
        return colored(C_BLUE, "󰌌 " .. name)
    end
end

-- ── Battery ────────────────────────────────────────────────────────────────

local function batteryLabel()
    local pct      = hs.battery.percentage()
    local charging = hs.battery.isCharging()  == true
    local charged  = hs.battery.isCharged()   == true
    log("battery pct=" .. tostring(pct) .. " charging=" .. tostring(charging) .. " charged=" .. tostring(charged))

    if pct == nil then return colored(C_GREEN, "󰚥") end  -- desktop / no battery

    local p = math.floor(pct + 0.5)

    if charging and not charged then
        return colored(C_GREEN, "󰂄 " .. p .. "%")
    elseif charged then
        return colored(C_GREEN, "󰁹 " .. p .. "%")
    else
        local idx = math.min(math.floor(p / 10) + 1, 11)
        local fg  = p <= 15 and C_RED or p <= 30 and C_ORANGE or C_YELLOW
        return colored(fg, ICONS_DISCHARGING[idx] .. " " .. p .. "%")
    end
end

-- ── CPU ────────────────────────────────────────────────────────────────────

-- Uses hs.host.cpuUsage(interval, callback) — the non-blocking two-sample API.
-- It takes two snapshots CPU_INTERVAL_S seconds apart and delivers percentages
-- to the callback, so no manual tick bookkeeping is needed.
local function scheduleCpuUpdate()
    hs.host.cpuUsage(CPU_INTERVAL_S, function(result)
        local pct = 0
        if result and result.overall then
            pct = math.floor((result.overall.active or 0) + 0.5)
        end
        if pct >= 60 then
            local fg = pct >= 90 and C_RED or C_YELLOW
            pushCached("cpu", colored(fg, "󰻠 " .. pct .. "%"))
        else
            pushCached("cpu", "")
        end
        scheduleCpuUpdate()
    end)
end

-- ── Memory ─────────────────────────────────────────────────────────────────

local function fmtGiB(mib)
    if mib >= 1024 then
        return string.format("%.1f", mib / 1024) .. "G"
    else
        return math.floor(mib + 0.5) .. "M"
    end
end

local function memLabel()
    local vm = hs.host.vmStat()
    if not vm then return colored(C_MAUVE, "󰍛 ?") end
    local pageSize  = vm.pageSize or 4096
    local usedPages = (vm.pagesActive or 0) + (vm.pagesWiredDown or 0)
                    + (vm.pagesUsedByVMCompressor or 0)
    local totalMiB  = (vm.memSize or 0) / 1048576
    local usedMiB   = usedPages * pageSize / 1048576
    local pct       = totalMiB > 0 and (usedMiB / totalMiB * 100) or 0
    if pct < 70 then return "" end
    local fg        = pct >= 90 and C_RED or C_YELLOW
    return colored(fg, "󰍛 " .. fmtGiB(usedMiB))
end

-- ── VPN ────────────────────────────────────────────────────────────────────

-- Returns true if any utun*/ppp*/ipsec* interface has an IPv4 address.
-- macOS always creates utun0-utun3 for iCloud/Continuity — those have only
-- link-local IPv6, never IPv4.  A real VPN tunnel (WireGuard, OpenVPN,
-- Tailscale split-tunnel) will have IPv4 assigned.
local function isVpnActive()
    local ifaces = hs.network.interfaces()
    if not ifaces then return false end
    for _, iface in ipairs(ifaces) do
        if iface:match("^utun") or iface:match("^ppp") or iface:match("^ipsec") then
            local d = hs.network.interfaceDetails(iface)
            if d and d.IPv4 then
                return true
            end
        end
    end
    return false
end

local function vpnLabel()
    return isVpnActive() and colored(C_RED, "󰖂 VPN") or ""
end

-- ── Focus Mode ─────────────────────────────────────────────────────────────

-- Reads Focus state via Accessibility on the Control Centre menu bar item
-- (AXIdentifier = com.apple.menuextra.focusmode).
-- No Full Disk Access required — only Accessibility permission (already granted).
-- When Focus is OFF the item has AXValue = nil and no visible icon text.
-- When Focus is ON  the item has AXValue = "<mode name>" (e.g. "Do Not Disturb").
-- Falls back to "" (empty) on any error so the widget stays hidden.

local function readFocusMenuBarValue()
    local cc = hs.application.find("Control Centre")
    if not cc then return nil end
    local ax = hs.axuielement.applicationElement(cc)
    if not ax then return nil end
    -- Control Centre has one child: AXMenuBar
    local topChildren = ax:attributeValue("AXChildren") or {}
    local menubar = topChildren[1]
    if not menubar then return nil end
    local children = menubar:attributeValue("AXChildren") or {}
    for _, item in ipairs(children) do
        local id = item:attributeValue("AXIdentifier") or ""
        if id == "com.apple.menuextra.focusmode" then
            return item:attributeValue("AXValue")  -- nil or string when active
        end
    end
    return nil
end

local function focusLabel()
    local val = readFocusMenuBarValue()
    if not val or val == "" then return "" end
    -- val is a human-readable name like "Do Not Disturb", "Work", "Personal" etc.
    -- Pick an icon based on common names.
    local icons = {
        ["Do Not Disturb"] = "󰂶",
        ["Work"]           = "󰢾",
        ["Personal"]       = "󱗽",
        ["Fitness"]        = "󰈿",
        ["Gaming"]         = "󰊗",
        ["Mindfulness"]    = "󰓏",
        ["Sleep"]          = "󰒲",
    }
    local icon = icons[val] or "󱑙"
    return colored(C_MAUVE, icon .. " " .. val)
end

-- ── Date / Time ────────────────────────────────────────────────────────────

-- Use hs.execute to get the date/time with explicit TZ, avoiding any
-- potential mismatch between Hammerspoon's Lua env and the system TZ.
local function dateLabel()
    local out, ok = hs.execute("TZ=Europe/Amsterdam date +'%a %d %b'")
    if not ok or not out or out == "" then
        out = os.date("%a %d %b")
    end
    out = out:gsub("%s+$", "")  -- strip trailing newline
    return colored(C_BLUE, "󰸗 " .. out)
end

local function timeLabel()
    local out, ok = hs.execute("TZ=Europe/Amsterdam date +'%H:%M'")
    if not ok or not out or out == "" then
        out = os.date("%H:%M")
    end
    out = out:gsub("%s+$", "")
    return colored(C_GREEN, "󰥔 " .. out)
end

-- Recompute all widget labels (using the current C_* color variables) and push
-- them to every active session.  Used after a theme/color change.
local function recomputeAll()
    pushCached("vpn",      vpnLabel())
    pushCached("focus",    focusLabel())
    pushCached("keyboard", keyboardLabel())
    pushCached("battery",  batteryLabel())
    pushCached("memory",   memLabel())
    pushCached("date",     dateLabel())
    pushCached("time",     timeLabel())
    -- CPU is self-scheduling; the next tick will pick up the new colors
    -- automatically.  Clear the cached value so no stale color flickers.
    lastValues["cpu"] = nil
end

-- ── URL handler: new-session bootstrap ────────────────────────────────────
-- fish calls: hs -c "ZJStatusPushAll('session-name')"
-- (also still bound to hammerspoon:// for compatibility)
-- We register the session, then push all current values to it.

-- Global function callable via hs IPC CLI:
--   hs -c "ZJStatusPushAll('session-name')"
function ZJStatusPushAll(name)
    log("ZJStatusPushAll called name=" .. tostring(name))
    if name and isValidSessionName(name) then
        registerSession(name)
        pushToSession(name)
        hs.timer.doAfter(4, function() pushToSession(name) end)
    else
        pushAll()
        hs.timer.doAfter(4, pushAll)
    end
end

-- Global function called by apply-theme-zellij after colors.lua is written.
-- Reloads the palette and recomputes all widget labels with the new colors.
function ZJStatusReloadColors()
    log("ZJStatusReloadColors called")
    if loadColors() then
        recomputeAll()
    end
end

local function setupUrlHandler()
    hs.urlevent.bind("zjstatus-push-all", function(_, params)
        local name = params and params.session
        log("urlevent zjstatus-push-all fired name=" .. tostring(name))
        ZJStatusPushAll(name)
    end)
end

-- ── init / cleanup ─────────────────────────────────────────────────────────

function M.init()
    zellijBin = resolveZellij()
    if not zellijBin then
        print("zjstatus-widgets: zellij not found in PATH, plugin disabled")
        return
    end

    -- Load theme colors from file written by apply-theme-zellij (if present).
    loadColors()

    -- Watch for theme changes: apply-theme-zellij rewrites colors.lua, which
    -- triggers this callback.  We reload colors then recompute all widget labels
    -- so every running session reflects the new palette immediately.
    M._colorsWatcher = hs.pathwatcher.new(COLORS_FILE, function()
        log("colors file changed, reloading palette")
        if loadColors() then
            recomputeAll()
        end
    end):start()

    -- Keyboard: hs.keycodes.inputSourceChanged is the correct native callback
    hs.keycodes.inputSourceChanged(function()
        log("keyboard inputSourceChanged fired")
        pushCached("keyboard", keyboardLabel())
    end)

    -- VPN: event-driven via reachability watcher (fires on any network change)
    M._reachWatcher = hs.network.reachability.internet()
    M._reachWatcher:setCallback(function(_, _)
        pushCached("vpn", vpnLabel())
    end)
    M._reachWatcher:start()

    -- Focus Mode: polled every 5 s via AX on Control Centre menu bar item.
    -- Distributed notifications for Focus are not reliably delivered to
    -- non-sandboxed apps, so polling is the pragmatic fallback.
    M._focusTimer = hs.timer.doEvery(5, function()
        pushCached("focus", focusLabel())
    end)

    -- Battery: instant via battery watcher
    M._batteryWatcher = hs.battery.watcher.new(function()
        pushCached("battery", batteryLabel())
    end)
    M._batteryWatcher:start()

    -- CPU: non-blocking two-sample measurement, self-rescheduling
    scheduleCpuUpdate()

    -- Memory: polled every 10 s
    M._memTimer = hs.timer.doEvery(MEM_INTERVAL_S, function()
        pushCached("memory", memLabel())
    end)

    -- Date: polled every 60 s
    M._dateTimer = hs.timer.doEvery(60, function()
        pushCached("date", dateLabel())
    end)

    -- Time: polled every 10 s
    M._timeTimer = hs.timer.doEvery(10, function()
        pushCached("time", timeLabel())
    end)

    -- URL handler for new-session bootstrap
    setupUrlHandler()

    -- Session list: seed cache once at startup, then prune dead sessions
    -- every SESSION_INTERVAL_S. Normal operation never needs list-sessions —
    -- sessions register themselves via the URL handler.
    refreshSessions(function()
        pushCached("vpn",      vpnLabel())
        pushCached("focus",    focusLabel())
        pushCached("keyboard", keyboardLabel())
        pushCached("battery",  batteryLabel())
        pushCached("memory",   memLabel())
        pushCached("date",     dateLabel())
        pushCached("time",     timeLabel())
        hs.timer.doAfter(2, pushAll)
    end)
    M._sessionTimer = hs.timer.doEvery(SESSION_INTERVAL_S, function()
        refreshSessions()  -- prune dead sessions from cache
    end)
end

function M.cleanup()
    hs.keycodes.inputSourceChanged()  -- clear the callback
    if M._wifiWatcher      then M._wifiWatcher:stop();    M._wifiWatcher = nil end
    if M._batteryWatcher   then M._batteryWatcher:stop(); M._batteryWatcher = nil end
    if M._memTimer         then M._memTimer:stop();       M._memTimer = nil end
    if M._focusTimer       then M._focusTimer:stop();     M._focusTimer = nil end
    if M._sessionTimer     then M._sessionTimer:stop();   M._sessionTimer = nil end
    if M._dateTimer        then M._dateTimer:stop();      M._dateTimer = nil end
    if M._timeTimer        then M._timeTimer:stop();      M._timeTimer = nil end
    if M._reachWatcher     then M._reachWatcher:stop();   M._reachWatcher = nil end
    if M._focusWatcher     then M._focusWatcher:stop();   M._focusWatcher = nil end
    if M._colorsWatcher    then M._colorsWatcher:stop();  M._colorsWatcher = nil end
    hs.urlevent.bind("zjstatus-push-all", nil)
    zellijBin      = nil
    lastValues     = {}
    cachedSessions = {}
end

return M
