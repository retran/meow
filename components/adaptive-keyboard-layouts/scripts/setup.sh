#!/usr/bin/env bash

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if [ "${OSTYPE#darwin}" = "${OSTYPE}" ]; then
  ui_warning "This component is designed exclusively for macOS."
  exit 0
fi

if ! [ -d "/Applications/Hammerspoon.app" ] && ! command -v hs >/dev/null 2>&1; then
  ui_warning "Hammerspoon is required but not found. Please install Hammerspoon or ensure the 'hs' command is in your PATH."
  exit 0
fi

ui_action_start "Configuring Adaptive Keyboard functionality..."

ui_info "Attempting to restart Hammerspoon for configuration changes."

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "Stopping Hammerspoon..."
  osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  sleep 2
fi

ui_info "Starting Hammerspoon..."
open -a Hammerspoon 2>/dev/null || true
sleep 3

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "Adaptive Keyboard configured successfully."
else
  ui_warning "Failed to restart Hammerspoon. Please ensure Hammerspoon is installed and running correctly."
fi
