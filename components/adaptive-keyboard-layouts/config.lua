local config = {}

-- Default keyboard configurations
config.keyboards = {
  dasKeyboard = {
    name = "Das Keyboard",
    vendorID = 0x24f0,
    productID = 0x0140,
    layouts = {
      abc = { id = 252, name = "ABC" },
      russianWin = { id = 19458, name = "RussianWin" }
    }
  },
  macbookPro = {
    name = "MacBook Pro",
    layouts = {
      abc = { id = 252, name = "ABC" },
      russian = { id = 19456, name = "Russian" }
    }
  }
}

-- Default layout preferences
config.preferences = {
  showAlerts = true,
  alertDuration = 1.5,
  debugMode = false
}

return config
