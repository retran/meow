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

-- Weather location: URL-safe characters only (letters, digits, %, +, ,, /, -)
-- Override via hs.settings: hs.settings.set("zjstatus.weatherLocation", "Rotterdam")
local WEATHER_LOCATION_DEFAULT = "Amsterdam"
local WEATHER_INTERVAL_S       = 1800   -- 30 minutes
local CPU_INTERVAL_S           = 5
local MEM_INTERVAL_S           = 10
local SESSION_INTERVAL_S       = 10    -- async session list refresh cadence (fallback only)

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
M._weatherTimer     = nil
M._sessionTimer     = nil

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
local function refreshSessions(callback)
    if not zellijBin then return end
    hs.task.new(zellijBin, function(code, out, _)
        if code == 0 and out then
            cachedSessions = parseSessions(out)
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
    if not src then return "󰌌 ?" end
    local name = src
        :gsub("^com%.apple%.keylayout%.", "")
        :gsub("^com%.apple%.inputmethod%.", "")
    name = name:match("%.([^%.]+)$") or name
    if name == "ABC" or name == "US"
            or name:find("^USInternational") or name:find("^British")
            or name:find("^Australian") then
        return "󰌌 EN"
    elseif name:find("^Russian") then
        return "󰌌 RU"
    else
        return "󰌌 " .. name
    end
end

-- ── Wi-Fi / network ────────────────────────────────────────────────────────

-- Returns the name of the first WiFi interface that is currently associated,
-- or nil if none.  Detected via the AirPort key in hs.network.interfaceDetails().
-- BSSID is redacted by Location Services so we use CHANNEL (non-zero = associated)
-- and presence of IPv4 as the association signal instead.
local function connectedWifiInterface()
    local ifaces = hs.network.interfaces()
    if not ifaces then return nil end
    for _, iface in ipairs(ifaces) do
        local d = hs.network.interfaceDetails(iface)
        if d and d.AirPort and d.IPv4 then
            local ch = d.AirPort.CHANNEL
            if type(ch) == "number" and ch > 0 then
                return iface
            end
        end
    end
    return nil
end

local function networkLabel()
    -- Try SSID first (requires Location Services → Wi-Fi Networking)
    local ssid = hs.wifi.currentNetwork()
    if ssid and ssid ~= "" then
        return "󰤨 " .. ssid
    end

    -- SSID is nil/empty (Location Services not granted or not on WiFi).
    -- Check if we have an associated WiFi interface anyway.
    if connectedWifiInterface() then
        return "󰤨 WiFi"
    end

    -- No WiFi — check for any wired/other IPv4 interface
    local ifaces = hs.network.interfaces()
    if ifaces then
        for _, iface in ipairs(ifaces) do
            local d = hs.network.interfaceDetails(iface)
            if d and d.IPv4 and iface ~= "lo0" and not d.AirPort then
                return "󰈁 " .. iface
            end
        end
    end

    return "󰤭"
end

-- ── Battery ────────────────────────────────────────────────────────────────

local function batteryLabel()
    local pct      = hs.battery.percentage()
    local charging = hs.battery.isCharging()  == true
    local charged  = hs.battery.isCharged()   == true
    log("battery pct=" .. tostring(pct) .. " charging=" .. tostring(charging) .. " charged=" .. tostring(charged))

    if pct == nil then return "󰚥" end  -- desktop / no battery

    local p = math.floor(pct + 0.5)

    if charging and not charged then
        return "󰂄 " .. p .. "%"
    elseif charged then
        return "󰁹 " .. p .. "%"
    else
        local idx = math.min(math.floor(p / 10) + 1, 11)
        return ICONS_DISCHARGING[idx] .. " " .. p .. "%"
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
        pushCached("cpu", "󰻠 " .. pct .. "%")
        scheduleCpuUpdate()
    end)
end

-- ── Memory ─────────────────────────────────────────────────────────────────

local function memLabel()
    local vm = hs.host.vmStat()
    if not vm then return "󰍛 ?" end
    local pages = (vm.pagesActive or 0) + (vm.pagesWiredDown or 0)
                + (vm.pagesUsedByVMCompressor or 0)
    local pageSize = vm.pageSize or 4096
    local usedMiB = math.floor(pages * pageSize / 1048576 + 0.5)
    return "󰍛 " .. usedMiB .. "M"
end

-- ── Weather ────────────────────────────────────────────────────────────────

local function isValidLocation(loc)
    return type(loc) == "string"
        and #loc >= 1 and #loc <= 64
        and loc:match("^[%w%%%.%+%,%-/]+$") ~= nil
end

local function fetchWeather()
    local loc = hs.settings.get("zjstatus.weatherLocation") or WEATHER_LOCATION_DEFAULT
    if not isValidLocation(loc) then loc = WEATHER_LOCATION_DEFAULT end
    local url = "https://wttr.in/" .. loc .. "?format=1"
    hs.http.asyncGet(url, nil, function(status, body, _)
        if status == 200 and body and body ~= "" then
            local val = body:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            if val ~= "" then pushCached("weather", val) end
        end
    end)
end

-- ── URL handler: new-session bootstrap ────────────────────────────────────
-- fish calls: open "hammerspoon://zjstatus-push-all?session=<name>"
-- We register the session, then push all current values to it.

local function setupUrlHandler()
    hs.urlevent.bind("zjstatus-push-all", function(_, params)
        local name = params and params.session
        if name and isValidSessionName(name) then
            -- Register and push to this specific session only
            registerSession(name)
            pushToSession(name)
            -- Re-send after 4 s to survive zjstatus startup latency
            hs.timer.doAfter(4, function() pushToSession(name) end)
        else
            -- No session param: push to all known sessions (legacy / manual trigger)
            pushAll()
            hs.timer.doAfter(4, pushAll)
        end
    end)
end

-- ── init / cleanup ─────────────────────────────────────────────────────────

function M.init()
    zellijBin = resolveZellij()
    if not zellijBin then
        print("zjstatus-widgets: zellij not found in PATH, plugin disabled")
        return
    end

    -- Keyboard: hs.keycodes.inputSourceChanged is the correct native callback
    hs.keycodes.inputSourceChanged(function()
        log("keyboard inputSourceChanged fired")
        pushCached("keyboard", keyboardLabel())
    end)

    -- Wi-Fi: instant via wifi watcher
    M._wifiWatcher = hs.wifi.watcher.new(function()
        pushCached("network", networkLabel())
    end)
    M._wifiWatcher:start()

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

    -- Weather: fetched every 30 min; first fetch immediately
    fetchWeather()
    M._weatherTimer = hs.timer.doEvery(WEATHER_INTERVAL_S, fetchWeather)

    -- URL handler for new-session bootstrap
    setupUrlHandler()

    -- Session list: seed cache once at startup, then prune dead sessions
    -- every SESSION_INTERVAL_S. Normal operation never needs list-sessions —
    -- sessions register themselves via the URL handler.
    refreshSessions(function()
        pushCached("keyboard", keyboardLabel())
        pushCached("network",  networkLabel())
        pushCached("battery",  batteryLabel())
        pushCached("memory",   memLabel())
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
    if M._weatherTimer     then M._weatherTimer:stop();   M._weatherTimer = nil end
    if M._sessionTimer     then M._sessionTimer:stop();   M._sessionTimer = nil end
    hs.urlevent.bind("zjstatus-push-all", nil)
    zellijBin      = nil
    lastValues     = {}
    cachedSessions = {}
end

return M
