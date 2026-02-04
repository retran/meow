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
-- @file: components/adaptive-keyboard-layouts/config/init.lua
-- @brief: Keyboard layout configuration for adaptive input management.
-- @author: Andrew Vasilyev
-- @license: MIT
--
local keyboardLayouts = {}

keyboardLayouts.config = {
  dasKeyboard = {
    vendorID = 0x24f0,
    productID = 0x0140,
    layoutScript = "set_das_keyboard_layouts.sh"
  },
  macbookPro = {
    layoutScript = "set_mbp_keyboard_layouts.sh"
  }
}

local function runScript(scriptPath, description)
  local basePath = os.getenv("HOME") .. "/.meow/.installed/components/adaptive-keyboard-layouts/scripts/"
  local scriptFullPath = basePath .. scriptPath
  local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      hs.alert.show(scriptPath .. " failed", 2)
    end
  end, {scriptFullPath})
  if not task then
    hs.alert.show("Failed to execute script", 2)
    return
  end
  task:start()
end

local function isDasKeyboardConnected()
  for _, device in ipairs(hs.usb.attachedDevices()) do
    if device.vendorID == keyboardLayouts.config.dasKeyboard.vendorID and
       device.productID == keyboardLayouts.config.dasKeyboard.productID then
      return true
    end
  end
  return false
end

local function setKeyboardLayoutForCurrentState(showAlert)
  local showAlert = showAlert == nil and true or showAlert

  if isDasKeyboardConnected() then
    runScript(keyboardLayouts.config.dasKeyboard.layoutScript, "Das Keyboard")
    if showAlert then
      hs.alert.show("Das Keyboard connected.", 1.5)
    end
  else
    runScript(keyboardLayouts.config.macbookPro.layoutScript, "MacBook Pro Keyboard")
    if showAlert then
      hs.alert.show("Das Keyboard disconnected.", 1.5)
    end
  end
end

local function deviceConnected(event)
  if event.vendorID == keyboardLayouts.config.dasKeyboard.vendorID and
     event.productID == keyboardLayouts.config.dasKeyboard.productID then
    if event.eventType == "added" then
      setKeyboardLayoutForCurrentState(true)
    elseif event.eventType == "removed" then
      setKeyboardLayoutForCurrentState(true)
    end
  end
end

function keyboardLayouts.init()
  if keyboardLayouts.usbWatcher then
    keyboardLayouts.usbWatcher:stop()
  end

  keyboardLayouts.usbWatcher = hs.usb.watcher.new(deviceConnected)
  keyboardLayouts.usbWatcher:start()

  setKeyboardLayoutForCurrentState(true)
  hs.timer.doAfter(2, function()
    setKeyboardLayoutForCurrentState(false)
  end)
  hs.timer.doAfter(5, function()
    setKeyboardLayoutForCurrentState(false)
  end)

  hs.alert.show("⌨️ Adaptive keyboard layouts ready", 2)
end

function keyboardLayouts.cleanup()
  if keyboardLayouts.usbWatcher then
    keyboardLayouts.usbWatcher:stop()
    keyboardLayouts.usbWatcher = nil
  end
end

return keyboardLayouts
