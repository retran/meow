#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if [[ "$OSTYPE" != "darwin"* ]]; then
  ui_warning "$(fmt "meowvim_keyboard_macos_only")"
  exit 0
fi

if ! [[ -d "/Applications/Hammerspoon.app" ]] && ! command -v hs >/dev/null 2>&1; then
  ui_warning "$(fmt "meowvim_keyboard_hammerspoon_required")"
  exit 0
fi

if ! command -v nvim >/dev/null 2>&1; then
  ui_warning "$(fmt "meowvim_keyboard_neovim_required")"
  exit 0
fi

ui_action_start "$(fmt "meowvim_keyboard_configuring")"

ui_info "$(fmt "meowvim_keyboard_restarting_hammerspoon")"

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "$(fmt "meowvim_keyboard_stopping_hammerspoon")"
  osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  sleep 2
fi

ui_info "$(fmt "meowvim_keyboard_starting_hammerspoon")"
open -a Hammerspoon 2>/dev/null || true
sleep 3

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "$(fmt "meowvim_keyboard_configured_successfully")"
  ui_info "$(fmt "meowvim_keyboard_integration_ready")"
else
  ui_warning "$(fmt "meowvim_keyboard_restart_failed")"
fi
