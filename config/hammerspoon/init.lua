local dasKeyboardLayoutScript = "/Users/retran/.meow/scripts/set_das_keyboard_layouts.sh"
local macbookProKeyboardLayoutScript = "/Users/retran/.meow/scripts/set_mbp_keyboard_layouts.sh"

local dasKeyboard = {
  vendorID = 0x24f0,
  productID = 0x0140,
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
    if device.vendorID == dasKeyboard.vendorID and device.productID == dasKeyboard.productID then
      return true
    end
  end
  return false
end

local function setKeyboardLayoutForCurrentState(showAlert)
  local showAlert = showAlert == nil and true or showAlert

  if isDasKeyboardConnected() then
    runScript(dasKeyboardLayoutScript, "Das Keyboard")
    if showAlert then
      hs.alert.show("Das Keyboard connected.", 1.5)
    end
  else
    runScript(macbookProKeyboardLayoutScript, "MacBook Pro Keyboard")
    if showAlert then
      hs.alert.show("Das Keyboard disconnected.", 1.5)
    end
  end
end

local function deviceConnected(event)
  if event.vendorID == dasKeyboard.vendorID and event.productID == dasKeyboard.productID then
    if event.eventType == "added" then
      setKeyboardLayoutForCurrentState(true)
    elseif event.eventType == "removed" then
      setKeyboardLayoutForCurrentState(true)
    end
  end
end

if usbWatcher then
  usbWatcher:stop()
end

usbWatcher = hs.usb.watcher.new(deviceConnected)
usbWatcher:start()

setKeyboardLayoutForCurrentState(true)

hs.alert.show("🚀 Keyboard layout manager ready", 2)
