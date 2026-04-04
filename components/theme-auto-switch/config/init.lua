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
-- @brief: Automatic theme switching using Hammerspoon (event-driven)
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
  if themeAutoSwitch.watcher then
    themeAutoSwitch.watcher:stop()
    themeAutoSwitch.watcher = nil
  end
  
  local mode = getThemeMode()
  log(string.format("[theme-auto-switch] Starting appearance watcher (mode: %s)", mode))
  
  themeAutoSwitch.watcher = hs.distributednotifications.new(function()
    log("[theme-auto-switch] Appearance changed")
    applyTheme()
  end, "AppleInterfaceThemeChangedNotification")
  themeAutoSwitch.watcher:start()
  
  log("[theme-auto-switch] Watcher started")
  hs.alert.show("🎨 Theme auto-switch ready (" .. mode .. " mode)", 2)
end

function themeAutoSwitch.cleanup()
  if themeAutoSwitch.watcher then
    themeAutoSwitch.watcher:stop()
    themeAutoSwitch.watcher = nil
  end
end

return themeAutoSwitch
