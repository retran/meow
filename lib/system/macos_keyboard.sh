#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

# Set keyboard layouts for macOS
# Usage: set_macos_keyboard_layouts LAYOUT_TYPE
# LAYOUT_TYPE: "das" or "mbp"
set_macos_keyboard_layouts() {
  local layout_type="$1"

  if [[ "$OSTYPE" != "darwin"* ]]; then
    warning "macOS keyboard layout configuration only works on macOS"
    return 1
  fi

  local russian_layout_id
  local russian_layout_name

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
      error "Unknown layout type: $layout_type. Use 'das' or 'mbp'"
      return 1
      ;;
  esac

  local is_russian_selected
  is_russian_selected=$(defaults read com.apple.HIToolbox AppleSelectedInputSources | grep -c "$russian_layout_name" || echo "0")

  action_msg "Configuring keyboard layouts for $layout_type..."

  # Set enabled input sources
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

  # Restore Russian layout if it was selected
  if [[ "$is_russian_selected" -gt 0 ]]; then
    action_msg "Restoring active Russian layout..."
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

  # Restart the input menu agent
  pkill TextInputMenuAgent 2>/dev/null || true

  success_tick_msg "Keyboard layouts configured for $layout_type"
}
