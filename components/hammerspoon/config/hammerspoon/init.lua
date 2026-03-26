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
-- @file: components/hammerspoon/config/hammerspoon/init.lua
-- @brief: Main configuration file for Hammerspoon window management.
-- @author: Andrew Vasilyev
-- @license: MIT
--
-- Load hs.ipc so the `hs` CLI tool can send commands to Hammerspoon.
-- This is required for the zjstatus-widgets new-session bootstrap:
-- fish calls `hs -c "..."` instead of `open hammerspoon://...` because
-- `open` is unreliable from background/non-GUI processes (zellij panes).
require("hs.ipc")

local installedComponents = {}

local function isComponentInstalled(component)
  local enabledDir = os.getenv("HOME") .. "/.meow/.installed/components/"
  local pluginPath = enabledDir .. component .. "/component.yaml"

  local f = io.open(pluginPath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function loadConfig(componentName)
  if not isComponentInstalled(componentName) then
    return false
  end

  local path = os.getenv("HOME") .. "/.meow/.installed/components/" .. componentName .. "/config/init.lua"
  local success, component = pcall(dofile, path)

  if success and component then
    installedComponents[componentName] = component

    if type(component.init) == "function" then
      local initSuccess, err = pcall(component.init)
      if not initSuccess then
        print("Failed to initialize plugin " .. componentName .. ": " .. tostring(err))
        return false
      end
    end

    print("Loaded plugin: " .. componentName)
    return true
  else
    return false
  end
end

local function cleanupComponents()
  for pluginName, plugin in pairs(installedComponents) do
    if type(plugin.cleanup) == "function" then
      pcall(plugin.cleanup)
    end
  end
  installedComponents = {}
end

local function loadInstalledPlugins()
  local pluginsDir = os.getenv("HOME") .. "/.meow/.installed/components/"

  local handle = io.popen("ls " .. pluginsDir .. " 2>/dev/null")
  if handle then
    for componentName in handle:lines() do
      -- TODO skip components that are not hammerspoon components
      loadConfig(componentName)
    end
    handle:close()
  end
end

cleanupComponents()

loadInstalledPlugins()
