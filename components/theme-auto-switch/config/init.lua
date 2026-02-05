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
-- @file: components/theme-auto-switch/config/init.lua
-- @brief: Automatic theme switching using Hammerspoon (polling-based)
-- @author: Andrew Vasilyev
-- @license: MIT
--

local themeAutoSwitch = {}

-- Logging function
local logFile = "/tmp/hammerspoon-theme-watcher.log"
local function log(message)
  local file = io.open(logFile, "a")
  if file then
    file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. message .. "\n")
    file:close()
  end
  print(message)
end

-- Get current system appearance
local function getSystemAppearance()
  local _, appearance = hs.osascript.applescript([[
    tell application "System Events"
      tell appearance preferences
        return dark mode
      end tell
    end tell
  ]])
  
  if appearance then
    return "dark"
  else
    return "light"
  end
end

-- Get theme mode from config (auto or manual)
local function getThemeMode()
  local configLib = os.getenv("HOME") .. "/.meow/lib/config/config.sh"
  local result = hs.execute(
    string.format('export MEOW="${MEOW:-$HOME/.meow}" && source "%s" 2>/dev/null && meow_config_get "theme.mode" "auto" 2>/dev/null', configLib),
    true
  )
  
  if result then
    -- Extract just the last line (the actual output), trim whitespace
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
    if #lines > 0 then
      local mode = lines[#lines]:gsub("^%s*(.-)%s*$", "%1")
      if mode == "auto" or mode == "manual" then
        return mode
      end
    end
  end
  
  return "auto"
end

-- Apply theme using meow-theme script
local function applyTheme()
  local mode = getThemeMode()
  
  if mode ~= "auto" then
    print("[theme-auto-switch] Auto mode disabled, skipping theme change")
    return
  end
  
  local appearance = getSystemAppearance()
  print("[theme-auto-switch] System appearance: " .. appearance)
  print("[theme-auto-switch] Auto mode enabled, applying theme...")
  
  local home = os.getenv("HOME")
  local meowThemeScript = home .. "/.meow/components/shell-essential/scripts/meow-theme"
  
  -- Run meow-theme apply synchronously with proper environment
  local cmd = string.format(
    'export HOME="%s" MEOW="%s/.meow" && "%s" apply 2>&1',
    home, home, meowThemeScript
  )
  
  local output, status = hs.execute(cmd, true)
  if status then
    print("[theme-auto-switch] Theme applied successfully")
  else
    print("[theme-auto-switch] Failed to apply theme: " .. (output or ""))
  end
end

function themeAutoSwitch.init()
  -- Stop existing timer if any
  if themeAutoSwitch.timer then
    themeAutoSwitch.timer:stop()
    themeAutoSwitch.timer = nil
  end
  
  local mode = getThemeMode()
  themeAutoSwitch.lastAppearance = getSystemAppearance()
  
  log(string.format(
    "[theme-auto-switch] Starting appearance watcher (current: %s, mode: %s)",
    themeAutoSwitch.lastAppearance,
    mode
  ))
  
  -- Create timer function
  local pollCount = 0
  local function timerCallback()
    pollCount = pollCount + 1
    local currentAppearance = getSystemAppearance()
    
    -- Log heartbeat every 60 polls (1 minute)
    if pollCount % 60 == 0 then
      log(string.format("[theme-auto-switch] Heartbeat: still watching (current: %s, polls: %d)", currentAppearance, pollCount))
    end
    
    if currentAppearance ~= themeAutoSwitch.lastAppearance then
      log(string.format(
        "[theme-auto-switch] Appearance changed: %s -> %s",
        themeAutoSwitch.lastAppearance,
        currentAppearance
      ))
      
      themeAutoSwitch.lastAppearance = currentAppearance
      applyTheme()
    end
  end
  
  -- Create and start timer (1 second interval)
  themeAutoSwitch.timer = hs.timer.new(1, timerCallback, true)
  themeAutoSwitch.timer:start()
  
  -- Verify timer is running
  if not themeAutoSwitch.timer:running() then
    log("[theme-auto-switch] ERROR: Timer failed to start!")
  else
    log("[theme-auto-switch] Timer started successfully")
  end
  
  hs.alert.show("🎨 Theme auto-switch ready (" .. mode .. " mode)", 2)
end

function themeAutoSwitch.cleanup()
  if themeAutoSwitch.timer then
    themeAutoSwitch.timer:stop()
    themeAutoSwitch.timer = nil
  end
end

return themeAutoSwitch
