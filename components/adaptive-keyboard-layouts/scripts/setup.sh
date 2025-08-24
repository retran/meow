#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if [[ "$OSTYPE" != "darwin"* ]]; then
  ui_warning "TODO: write message - adaptive_keyboard_macos_only"
  exit 0
fi

if ! [[ -d "/Applications/Hammerspoon.app" ]] && ! command -v hs >/dev/null 2>&1; then
  ui_warning "TODO: write message - adaptive_keyboard_hammerspoon_required"
  exit 0
fi

ui_action_start "TODO: write message - adaptive_keyboard_configuring"

ui_info "TODO: write message - adaptive_keyboard_restarting_hammerspoon"

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "TODO: write message - adaptive_keyboard_stopping_hammerspoon"
  osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  sleep 2
fi

ui_info "TODO: write message - adaptive_keyboard_starting_hammerspoon"
open -a Hammerspoon 2>/dev/null || true
sleep 3

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "TODO: write message - adaptive_keyboard_configured_successfully"
else
  ui_warning "TODO: write message - adaptive_keyboard_restart_failed"
fi
