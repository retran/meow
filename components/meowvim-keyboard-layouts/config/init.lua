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
-- @file: components/meowvim-keyboard-layouts/config/init.lua
-- @brief: Keyboard layout management for Neovim and Neovide integration.
-- @author: Andrew Vasilyev
-- @license: MIT
--
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
