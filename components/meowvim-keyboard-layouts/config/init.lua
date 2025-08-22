local meowvimKeyboardLayouts = {}

local lastInputSource = nil
local englishSource = "com.apple.keylayout.ABC"
local neovideAppName = "Neovide"
local alacrittyAppName = "Alacritty"
local DEBUG = false

local function switchLayoutByTitle(window, appName)
    if appName ~= neovideAppName and appName ~= alacrittyAppName then
        return
    end

    local title = window:title()
    if not string.find(title, "meowvim") then
        return
    end

    local currentSource = hs.keycodes.currentSourceID()

    if string.find(title, "%[I%]") then
        if lastInputSource ~= nil and currentSource ~= lastInputSource then
            if DEBUG then hs.console.printStyledtext("Switching to: " .. tostring(lastInputSource)) end
            hs.keycodes.currentSourceID(lastInputSource)
        end
    else
        lastInputSource = currentSource
        if currentSource ~= englishSource then
            if DEBUG then hs.console.printStyledtext("Switching to English") end
            hs.keycodes.currentSourceID(englishSource)
        end
    end
end

local function handleAppActivation(appName, eventType, app)
    if appName ~= neovideAppName and appName ~= alacrittyAppName then
        return
    end

    if eventType == hs.application.watcher.activated then
        local focusedWindow = hs.window.focusedWindow()
        if focusedWindow ~= nil then
            switchLayoutByTitle(focusedWindow, appName)
        end
    elseif eventType == hs.application.watcher.deactivated then
        lastInputSource = hs.keycodes.currentSourceID()
    end
end

function meowvimKeyboardLayouts.init()
    if meowvimKeyboardLayouts.titleWatcher then
        meowvimKeyboardLayouts.titleWatcher:unsubscribeAll()
        meowvimKeyboardLayouts.titleWatcher = nil
    end

    if meowvimKeyboardLayouts.appWatcher then
        meowvimKeyboardLayouts.appWatcher:stop()
        meowvimKeyboardLayouts.appWatcher = nil
    end

    meowvimKeyboardLayouts.titleWatcher = hs.window.filter.new({neovideAppName, alacrittyAppName})
    meowvimKeyboardLayouts.titleWatcher:subscribe(hs.window.filter.windowTitleChanged, switchLayoutByTitle)

    meowvimKeyboardLayouts.appWatcher = hs.application.watcher.new(handleAppActivation)
    meowvimKeyboardLayouts.appWatcher:start()

    hs.alert.show("Meowvim keyboard layouts ready", 1)
end

function meowvimKeyboardLayouts.cleanup()
    if meowvimKeyboardLayouts.titleWatcher then
        meowvimKeyboardLayouts.titleWatcher:unsubscribeAll()
        meowvimKeyboardLayouts.titleWatcher = nil
    end

    if meowvimKeyboardLayouts.appWatcher then
        meowvimKeyboardLayouts.appWatcher:stop()
        meowvimKeyboardLayouts.appWatcher = nil
    end
end

return meowvimKeyboardLayouts
