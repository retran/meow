# Hammerspoon Integration

`.meow` leverages [Hammerspoon](https://www.hammerspoon.org/), a powerful automation tool for macOS, to provide advanced system integrations that go beyond simple shell scripts. This includes automatic keyboard layout switching based on hardware, context-aware input management for Vim, and window management.

This guide explains the architecture of the Hammerspoon integration and how to build your own Lua-based components.

> **Important**: The Hammerspoon integration requires both the Hammerspoon.app and the `hs` command-line utility to be installed and available. The `hs` CLI utility is essential for scripts to interact with Hammerspoon programmatically. It is typically installed alongside Hammerspoon.app but may need to be enabled in Hammerspoon preferences.

## Architecture

Unlike a standard Hammerspoon setup where all configuration resides in a single `~/.hammerspoon/init.lua`, `.meow` employs a **modular plugin system**.

### The Core Loader

The core `hammerspoon` component installs a master `init.lua` file that acts as a plugin loader. Its responsibility is to:

1.  **Scan Installed Components**: It looks through the `~/.meow/.installed/components/` directory.
2.  **Identify Plugins**: It checks for components that have a `config/init.lua` file.
3.  **Lifecycle Management**: It dynamically loads each plugin and calls its `init()` function on startup and `cleanup()` on reload.

This means you can add or remove Lua functionality simply by installing or uninstalling `.meow` components, without ever touching the main Hammerspoon configuration file.

## Built-in Integrations

### Adaptive Keyboard Layouts

The `adaptive-keyboard-layouts` component automatically switches your macOS input sources based on the physical keyboard you are using.

- **Hardware Detection**: Uses `hs.usb.watcher` to detect when specific USB keyboards (e.g., Das Keyboard) are connected or disconnected.
- **Layout Switching**: Executes shell scripts (like `set_das_keyboard_layouts.sh`) to apply a specific set of input sources (e.g., "US" and "RussianWin") appropriate for that hardware.
- **Fallback**: Automatically reverts to a default profile (e.g., MacBook Pro internal keyboard layout) when the external keyboard is disconnected.

### meowvim Integration

The `meowvim-keyboard-layouts` component provides deep integration between the system and the Neovim editor (running in Neovide or Alacritty).

- **Context Awareness**: Watches window titles to detect when Neovim enters or exits Insert mode (indicated by flags like `[I]`).
- **Auto-Switching**:
  - **Leaving Insert Mode**: Automatically switches the system keyboard layout to English. This ensures that Vim normal mode commands (which usually require English) always work, regardless of what language you were typing in.
  - **Entering Insert Mode**: Restores the previous layout (e.g., Russian) so you can continue typing text immediately.

## Developing Hammerspoon Components

To create a component that extends Hammerspoon, your component structure must follow specific conventions.

### 1. Component Manifest

In your `component.yaml`, specify the type as `hammerspoon`. This helps with identification, although the loader primarily looks for the existence of the Lua config file.

```yaml
# components/my-plugin/component.yaml
description: My custom Hammerspoon automation
type: hammerspoon
platforms:
  - match:
      platform: macos
depends_on:
  - hammerspoon
```

### 2\. Lua Configuration

Create a `config/init.lua` file. This file **must** return a Lua table containing `init` and `cleanup` functions.

```lua
-- components/my-plugin/config/init.lua
local myPlugin = {}

-- Called when Hammerspoon loads or reloads
function myPlugin.init()
    hs.alert.show("My Plugin Loaded!")

    -- Example: Bind a hotkey
    myPlugin.hotkey = hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
      hs.alert.show("Hello from .meow!")
    end)
end

-- Called before the configuration is reloaded to prevent memory leaks
function myPlugin.cleanup()
    if myPlugin.hotkey then
        myPlugin.hotkey:delete()
    end
end

return myPlugin
```

### 3\. Symlinking

Ensure your `init.lua` is not symlinked directly to `~/.hammerspoon/init.lua` (that's reserved for the core loader). Instead, the core loader will `dofile` your script directly from the installed component path.

Therefore, you generally **do not** need a `symlinks` section for the Lua file itself, unless you are storing auxiliary configuration files in `~/.hammerspoon/`.

### 4\. External Scripts

If your Lua code needs to call shell scripts (like the keyboard switcher), place them in the `scripts/` directory of your component. You can reference them in Lua using absolute paths resolved via `os.getenv("HOME") .. "/.meow/.installed/components/..."`.

```lua
local scriptPath = os.getenv("HOME") .. "/.meow/.installed/components/my-plugin/scripts/action.sh"
hs.task.new(scriptPath, nil):start()
```
