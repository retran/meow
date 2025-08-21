local keyboardLayouts = {}

keyboardLayouts.config = {
  dasKeyboard = {
    vendorID = 0x24f0,
    productID = 0x0140,
    layoutScript = "/Users/retran/.meow/.installed/components/adaptive-keyboard-layouts/scripts/set_das_keyboard_layouts.sh"
  },
  macbookPro = {
    layoutScript = "/Users/retran/.meow/.installed/components/adaptive-keyboard-layouts/scripts/set_mbp_keyboard_layouts.sh"
  }
}

local function runScript(scriptPath, description)
  local task = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      hs.alert.show(description .. " failed", 2)
    end
  end)
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

  hs.alert.show("⌨️ Adaptive keyboard layouts ready", 2)
end

function keyboardLayouts.cleanup()
  if keyboardLayouts.usbWatcher then
    keyboardLayouts.usbWatcher:stop()
    keyboardLayouts.usbWatcher = nil
  end
end

return keyboardLayouts
