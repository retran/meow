#!/usr/bin/env bash
# @file:    components/adaptive-keyboard-layouts/scripts/macos_keyboard.sh
# @brief:   Installation or configuration script for adaptive-keyboard-layouts component.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${MEOW:-}" ] && [ -f "${MEOW}/lib/core/ui.sh" ]; then
  source "${MEOW}/lib/core/ui.sh"
fi

if [ -n "${_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_MACOS_KEYBOARD_SOURCED=1

MEOW="${MEOW:-$HOME/.meow}"

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"

set_macos_keyboard_layouts() {
  local layout_type="$1"

  if ! case "${OSTYPE:-}" in
    darwin*) true ;;
    *) false ;;
  esac then
    ui_warning "This function is designed for macOS only."
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
      ui_error "$(_f "Invalid layout type '%s'. Use 'das' or 'mbp'." "$layout_type")"
      return 1
      ;;
  esac

  local is_russian_selected=0
  if defaults read com.apple.HIToolbox AppleSelectedInputSources | rg -q "$russian_layout_name"; then
    is_russian_selected=1
  fi

  ui_action_start "$(_f "Setting keyboard layouts for %s..." "$layout_type")"

  if [ "${MEOW_DRY_RUN:-}" != "true" ]; then
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
  else
    ui_action_start "DRY-RUN: Setting keyboard layouts for $layout_type"
  fi

  if [ "$is_russian_selected" -eq 1 ]; then
    ui_action_start "Restoring previously active Russian layout."
    if [ "${MEOW_DRY_RUN:-}" != "true" ]; then
      defaults write com.apple.HIToolbox AppleSelectedInputSources -array \
        "<dict>
            <key>InputSourceKind</key>
            <string>Keyboard Layout</string>
            <key>KeyboardLayout ID</key>
            <integer>$russian_layout_id</integer>
            <key>KeyboardLayout Name</key>
            <string>$russian_layout_name</string>
        </dict>"
    else
      ui_action_start "DRY-RUN: Restoring previously active Russian layout."
    fi
  fi

  if [ "${MEOW_DRY_RUN:-}" != "true" ]; then
    pkill TextInputMenuAgent 2>/dev/null || true
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ] || [ "${MEOW_DRY_RUN:-}" = "true" ]; then
    ui_action_success "$(_f "Keyboard layouts configured successfully for %s." "$layout_type")"
  fi
}
