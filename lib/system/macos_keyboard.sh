#!/usr/bin/env bash

# Helper function for safe string formatting, injected by the inliner script.
_f() {
  local template="$1"
  shift
  printf -- "$template" "$@"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED=1

MEOW="${MEOW:-$HOME/.meow}"

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"

# Set keyboard layouts for macOS.
# This function configures the enabled input sources (keyboard layouts)
# and preserves the currently selected layout if it's one of the Russian layouts.
#
# Usage: set_macos_keyboard_layouts LAYOUT_TYPE
# LAYOUT_TYPE: "das" for Das Keyboard or "mbp" for MacBook Pro internal keyboard.
set_macos_keyboard_layouts() {
  local layout_type="$1"

  if [[ "$OSTYPE" != "darwin"* ]]; then
    ui_warning "This function only works on macOS"
    return 1
  fi

  local russian_layout_id
  local russian_layout_name

  # Determine the correct Russian layout ID and name based on the keyboard type.
  case "$layout_type" in
    "das")
      russian_layout_id="19458"
      russian_layout_name="RussianWin"
      ;;
    "mbp")
      russian_layout_id="19456"
      russian_layout_name="Russian"
      ;;
    *)
      ui_error "$(_f "Unknown layout type: %s. Use 'das' or 'mbp'" "$layout_type")"
      return 1
      ;;
  esac

  # Check if the specific Russian layout is currently selected.
  # We use `rg -q` (ripgrep) which is "quiet" and only returns an exit code,
  # making it ideal for conditional checks without capturing output.
  local is_russian_selected=0
  if defaults read com.apple.HIToolbox AppleSelectedInputSources | rg -q "$russian_layout_name"; then
    is_russian_selected=1
  fi

  ui_action_start "$(_f "Configuring keyboard layouts for %s..." "$layout_type")"

  # Set the enabled input sources to "ABC" (U.S.) and the chosen Russian layout.
  # This overwrites the existing list of enabled layouts.
  defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
    '<dict>
        <key>InputSourceKind</key>
        <string>Keyboard Layout</string>
        <key>KeyboardLayout ID</key>
        <integer>252</integer>
        <key>KeyboardLayout Name</key>
        <string>ABC</string>
    </dict>' \
    "<dict>
        <key>InputSourceKind</key>
        <string>Keyboard Layout</string>
        <key>KeyboardLayout ID</key>
        <integer>$russian_layout_id</integer>
        <key>KeyboardLayout Name</key>
        <string>$russian_layout_name</string>
    </dict>"

  # If the Russian layout was active before, restore it as the selected source.
  if [[ "$is_russian_selected" -eq 1 ]]; then
    ui_action_start "Restoring active Russian layout"
    defaults write com.apple.HIToolbox AppleSelectedInputSources -array \
      "<dict>
          <key>InputSourceKind</key>
          <string>Keyboard Layout</string>
          <key>KeyboardLayout ID</key>
          <integer>$russian_layout_id</integer>
          <key>KeyboardLayout Name</key>
          <string>$russian_layout_name</string>
      </dict>"
  fi

  pkill TextInputMenuAgent 2>/dev/null || true

  ui_action_success "$(_f "Keyboard layouts configured for %s" "$layout_type")"
}
