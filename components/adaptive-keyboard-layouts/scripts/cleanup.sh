#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "adaptive_keyboard_cleanup_running")"

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "$(get_static_message "adaptive_keyboard_cleaning_preferences")"

  rm -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist.backup" 2>/dev/null || true

  sudo rm -f /Library/Preferences/com.apple.HIToolbox.plist 2>/dev/null || true

  defaults delete com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null || true
  defaults delete com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null || true
fi

ui_info "$(get_static_message "adaptive_keyboard_cleaning_temp_files")"
rm -rf "/tmp/keyboard_layout_*" 2>/dev/null || true

ui_success "$(get_static_message "adaptive_keyboard_cleanup_completed")"
