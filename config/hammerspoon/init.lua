-- config/hammerspoon/init.lua - Hammerspoon configuration with plugin support

local pluginSystem = {}
local enabledPlugins = {}

local function isPluginEnabled(pluginName)
  local enabledDir = os.getenv("HOME") .. "/.meow/.installed/plugins/"
  local pluginPath = enabledDir .. pluginName

  local f = io.open(pluginPath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function loadPlugin(pluginName)
  if not isPluginEnabled(pluginName) then
    return false
  end

  local pluginPath = os.getenv("HOME") .. "/.meow/plugins/" .. pluginName .. "/init.lua"
  local success, plugin = pcall(dofile, pluginPath)

  if success and plugin then
    enabledPlugins[pluginName] = plugin

    if type(plugin.init) == "function" then
      local initSuccess, err = pcall(plugin.init)
      if not initSuccess then
        print("Failed to initialize plugin " .. pluginName .. ": " .. tostring(err))
        return false
      end
    end

    print("Loaded plugin: " .. pluginName)
    return true
  else
    print("Failed to load plugin " .. pluginName .. ": " .. tostring(plugin))
    return false
  end
end

local function cleanupPlugins()
  for pluginName, plugin in pairs(enabledPlugins) do
    if type(plugin.cleanup) == "function" then
      pcall(plugin.cleanup)
    end
  end
  enabledPlugins = {}
end

local function loadEnabledPlugins()
  local pluginsDir = os.getenv("HOME") .. "/.meow/.installed/plugins"

  local handle = io.popen("ls " .. pluginsDir .. " 2>/dev/null")
  if handle then
    for pluginName in handle:lines() do
      loadPlugin(pluginName)
    end
    handle:close()
  end
end

cleanupPlugins()

loadEnabledPlugins()
