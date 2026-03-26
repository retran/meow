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
local NET_INTERVAL_S           = 2     -- network traffic sampling interval
local SESSION_INTERVAL_S       = 10    -- async session list refresh cadence (fallback only)

-- Catppuccin Mocha palette (must match ZJSTATUS_COLORS in default.kdl)
local C_GREEN  = "#a6e3a1"
local C_YELLOW = "#f9e2af"
local C_ORANGE = "#fab387"
local C_RED    = "#f38ba8"
local C_MAUVE  = "#cba6f7"
local C_BLUE   = "#89b4fa"
local C_BG     = "#1e1e2e"

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
local netPrevBytes     = nil   -- {rx, tx} from last sample, for rate calc

-- Watchers / timers — kept in M so cleanup() can stop them
M._wifiWatcher      = nil
M._batteryWatcher   = nil
M._memTimer         = nil
M._diskTimer        = nil
M._weatherTimer     = nil
M._sessionTimer     = nil
M._netTimer         = nil
M._dateTimer        = nil
M._timeTimer        = nil

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

-- ── Network traffic ────────────────────────────────────────────────────────

-- Returns {name, isWifi} for the first active non-loopback interface, preferring WiFi.
local function activeInterface()
    local ifaces = hs.network.interfaces()
    if not ifaces then return nil end
    local fallback = nil
    for _, iface in ipairs(ifaces) do
        local d = hs.network.interfaceDetails(iface)
        if d and d.IPv4 and iface ~= "lo0" then
            if d.AirPort then
                local ch = d.AirPort.CHANNEL
                if type(ch) == "number" and ch > 0 then
                    return iface, true   -- connected WiFi — first choice
                end
            else
                fallback = fallback or iface
            end
        end
    end
    return fallback, false
end

-- Read cumulative rx/tx bytes for an interface via netstat.
local function readIfaceBytes(iface)
    local f = io.popen("netstat -ibn 2>/dev/null")
    if not f then return nil, nil end
    local rx, tx
    for line in f:lines() do
        -- Match the <Link#N> row for this interface
        if line:match("^" .. iface .. "%s") and line:match("<Link") then
            local fields = {}
            for v in line:gmatch("%S+") do fields[#fields+1] = v end
            -- netstat -ibn columns: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll
            rx = tonumber(fields[7])
            tx = tonumber(fields[10])
            break
        end
    end
    f:close()
    return rx, tx
end

-- Format bytes/s into a human-readable rate string.
local function fmtRate(bps)
    if bps >= 1048576 then
        return string.format("%.1fM", bps / 1048576)
    elseif bps >= 1024 then
        return string.format("%.0fK", bps / 1024)
    else
        return string.format("%dB", bps)
    end
end

local function updateNetwork()
    local iface, isWifi = activeInterface()
    if not iface then
        pushCached("network", "󰤭")
        netPrevBytes = nil
        return
    end

    local icon = isWifi and "󰤨" or "󰈁"
    local rx, tx = readIfaceBytes(iface)
    if not rx or not tx then
        pushCached("network", icon)
        netPrevBytes = nil
        return
    end

    -- Reset rate history if interface changed
    if netPrevBytes and netPrevBytes[3] ~= iface then
        netPrevBytes = nil
    end

    if netPrevBytes then
        local drx = math.max(0, rx - netPrevBytes[1])
        local dtx = math.max(0, tx - netPrevBytes[2])
        local rxRate = drx / NET_INTERVAL_S
        local txRate = dtx / NET_INTERVAL_S
        pushCached("network", icon .. " 󰁆 " .. fmtRate(rxRate) .. " 󰁞 " .. fmtRate(txRate))
    end

    netPrevBytes = {rx, tx, iface}
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
        local fg = pct >= 90 and C_RED or pct >= 60 and C_YELLOW or C_GREEN
        pushCached("cpu", colored(fg, "󰻠 " .. pct .. "%"))
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
    local fg        = pct >= 90 and C_RED or pct >= 70 and C_YELLOW or C_MAUVE
    return colored(fg, "󰍛 " .. fmtGiB(usedMiB))
end

-- ── Disk ───────────────────────────────────────────────────────────────────

local function diskLabel()
    local vol = hs.fs.volume.allVolumes(true)["/"]
    if not vol then return colored(C_YELLOW, "󰋊 ?") end
    local avail = vol.NSURLVolumeAvailableCapacityKey
    if not avail then return colored(C_YELLOW, "󰋊 ?") end
    local freeGiB = avail / 1073741824
    local fg = freeGiB <= 20 and C_RED or freeGiB <= 50 and C_YELLOW or C_GREEN
    return colored(fg, "󰋊 " .. string.format("%.0f", freeGiB) .. "G")
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

-- ── Weather ────────────────────────────────────────────────────────────────

-- WWO weather code → nerd font icon (nf-weather-*)
-- Codes from https://www.worldweatheronline.com/feed/wwoConditionCodes.txt
local WEATHER_ICONS = {
    [113] = "󰖙",  -- Clear / Sunny            nf-weather-day_sunny
    [116] = "󰖕",  -- Partly Cloudy            nf-weather-day_cloudy
    [119] = "󰖐",  -- Cloudy                   nf-weather-cloudy
    [122] = "󰖐",  -- Overcast                 nf-weather-cloudy
    [143] = "󰖑",  -- Mist                     nf-weather-fog
    [176] = "󰖗",  -- Patchy rain nearby       nf-weather-day_showers
    [179] = "󰖘",  -- Patchy snow nearby       nf-weather-day_snow
    [182] = "󰖘",  -- Patchy sleet nearby      nf-weather-day_snow
    [185] = "󰖘",  -- Patchy freezing drizzle  nf-weather-day_snow
    [200] = "󰖓",  -- Thundery outbreaks       nf-weather-day_thunderstorm
    [227] = "󰖚",  -- Blowing snow             nf-weather-snow_wind
    [230] = "󰖔",  -- Blizzard                 nf-weather-snowflake_cold
    [248] = "󰖑",  -- Fog                      nf-weather-fog
    [260] = "󰖑",  -- Freezing fog             nf-weather-fog
    [263] = "󰖒",  -- Patchy light drizzle     nf-weather-sprinkle
    [266] = "󰖒",  -- Light drizzle            nf-weather-sprinkle
    [281] = "󰖘",  -- Freezing drizzle         nf-weather-sleet
    [284] = "󰖘",  -- Heavy freezing drizzle   nf-weather-sleet
    [293] = "󰖗",  -- Patchy light rain        nf-weather-day_showers
    [296] = "󰖗",  -- Light rain               nf-weather-day_showers
    [299] = "󰖖",  -- Moderate rain at times   nf-weather-rain
    [302] = "󰖖",  -- Moderate rain            nf-weather-rain
    [305] = "󰖖",  -- Heavy rain at times      nf-weather-rain
    [308] = "󰖖",  -- Heavy rain               nf-weather-rain
    [311] = "󰖘",  -- Light freezing rain      nf-weather-sleet
    [314] = "󰖘",  -- Mod/heavy freezing rain  nf-weather-sleet
    [317] = "󰖘",  -- Light sleet              nf-weather-sleet
    [320] = "󰖘",  -- Mod/heavy sleet          nf-weather-sleet
    [323] = "󰖙",  -- Patchy light snow        nf-weather-day_snow
    [326] = "󰼶",  -- Light snow               nf-weather-snow
    [329] = "󰼶",  -- Patchy moderate snow     nf-weather-snow
    [332] = "󰼶",  -- Moderate snow            nf-weather-snow
    [335] = "󰖔",  -- Patchy heavy snow        nf-weather-snowflake_cold
    [338] = "󰖔",  -- Heavy snow               nf-weather-snowflake_cold
    [350] = "󰖘",  -- Ice pellets              nf-weather-sleet
    [353] = "󰖗",  -- Light rain shower        nf-weather-day_showers
    [356] = "󰖖",  -- Mod/heavy rain shower    nf-weather-rain
    [359] = "󰖖",  -- Torrential rain shower   nf-weather-rain
    [362] = "󰖘",  -- Light sleet showers      nf-weather-sleet
    [365] = "󰖘",  -- Mod/heavy sleet showers  nf-weather-sleet
    [368] = "󰼶",  -- Light snow showers       nf-weather-snow
    [371] = "󰖔",  -- Mod/heavy snow showers   nf-weather-snowflake_cold
    [374] = "󰖘",  -- Light ice pellet showers nf-weather-sleet
    [377] = "󰖘",  -- Mod/heavy ice pellets    nf-weather-sleet
    [386] = "󰖓",  -- Patchy rain w/ thunder   nf-weather-day_thunderstorm
    [389] = "󰖓",  -- Mod/heavy rain w/ thunder nf-weather-thunderstorm
    [392] = "󰖓",  -- Patchy snow w/ thunder   nf-weather-day_thunderstorm
    [395] = "󰖓",  -- Mod/heavy snow w/ thunder nf-weather-thunderstorm
}

local function isValidLocation(loc)
    return type(loc) == "string"
        and #loc >= 1 and #loc <= 64
        and loc:match("^[%w%%%.%+%,%-/]+$") ~= nil
end

local function fetchWeather()
    local loc = hs.settings.get("zjstatus.weatherLocation") or WEATHER_LOCATION_DEFAULT
    if not isValidLocation(loc) then loc = WEATHER_LOCATION_DEFAULT end
    local url = "https://wttr.in/" .. loc .. "?format=j1"
    hs.http.asyncGet(url, nil, function(status, body, _)
        if status ~= 200 or not body or body == "" then return end
        local ok, data = pcall(function() return hs.json.decode(body) end)
        if not ok or not data then return end
        local cc = data.current_condition and data.current_condition[1]
        if not cc then return end
        local code = tonumber(cc.weatherCode)
        local temp = cc.temp_C or "?"
        local icon = WEATHER_ICONS[code] or "󰖐"
        local sign = (tonumber(temp) or 0) >= 0 and "+" or ""
        pushCached("weather", icon .. " " .. sign .. temp .. "°C")
    end)
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

    -- Keyboard: hs.keycodes.inputSourceChanged is the correct native callback
    hs.keycodes.inputSourceChanged(function()
        log("keyboard inputSourceChanged fired")
        pushCached("keyboard", keyboardLabel())
    end)

    -- Wi-Fi: replaced by traffic poller below

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

    -- Disk: polled every 60 s (changes slowly)
    M._diskTimer = hs.timer.doEvery(60, function()
        pushCached("disk", diskLabel())
    end)

    -- Network traffic: sampled every NET_INTERVAL_S seconds
    updateNetwork()  -- first sample (seeds netPrevBytes, no display yet)
    M._netTimer = hs.timer.doEvery(NET_INTERVAL_S, updateNetwork)

    -- Date: polled every 60 s (changes once per day but cheap to check)
    M._dateTimer = hs.timer.doEvery(60, function()
        pushCached("date", dateLabel())
    end)

    -- Time: polled every 10 s (sub-minute resolution is fine for a status bar)
    M._timeTimer = hs.timer.doEvery(10, function()
        pushCached("time", timeLabel())
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
        pushCached("battery",  batteryLabel())
        pushCached("memory",   memLabel())
        pushCached("disk",     diskLabel())
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
    if M._diskTimer        then M._diskTimer:stop();      M._diskTimer = nil end
    if M._netTimer         then M._netTimer:stop();       M._netTimer = nil end
    if M._weatherTimer     then M._weatherTimer:stop();   M._weatherTimer = nil end
    if M._sessionTimer     then M._sessionTimer:stop();   M._sessionTimer = nil end
    if M._dateTimer        then M._dateTimer:stop();      M._dateTimer = nil end
    if M._timeTimer        then M._timeTimer:stop();      M._timeTimer = nil end
    hs.urlevent.bind("zjstatus-push-all", nil)
    zellijBin      = nil
    lastValues     = {}
    cachedSessions = {}
    netPrevBytes   = nil
end

return M
