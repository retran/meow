-- config/hammerspoon/init.lua - Hammerspoon configuration with component support

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
    print("Failed to load plugin " .. componentName .. ": " .. tostring(component))
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
