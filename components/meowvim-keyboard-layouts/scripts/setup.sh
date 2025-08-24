#!/usr/bin/env bash

# Argument 1: The name of the component being configured (e.g., "MeowVim Keyboard")
COMPONENT_NAME="$1"
# Argument 2: Path to the root of the MeowVim project
MEOW="$2"

# Source necessary library files
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

# Check if the operating system is macOS. This script is macOS-specific.
# Using 'case' for robust pattern matching compatible with Bash 3.2.
case "$OSTYPE" in
  darwin*)
    # Operating system is macOS, continue.
    ;;
  *)
    ui_warning "This script is intended for macOS only. Exiting."
    exit 0
    ;;
esac

# Check for Hammerspoon installation.
# Hammerspoon.app must be in /Applications or 'hs' command must be in PATH.
if ! [[ -d "/Applications/Hammerspoon.app" ]] && ! command -v hs >/dev/null 2>&1; then
  ui_warning "Hammerspoon is required for ${COMPONENT_NAME}. Please install it (e.g., via Homebrew) and ensure it's in /Applications or its 'hs' command is in your PATH. Exiting."
  exit 0
fi

ui_action_start "Configuring ${COMPONENT_NAME} keyboard integration..."

ui_info "Attempting to restart Hammerspoon to apply changes..."

# Check if Hammerspoon is currently running
if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "Stopping existing Hammerspoon process..."
  # Attempt to quit Hammerspoon gracefully. Suppress errors if it's already not responsive.
  osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  # Give Hammerspoon some time to shut down
  sleep 2
fi

ui_info "Starting Hammerspoon..."
# Open Hammerspoon application. Suppress errors if it fails to open for some reason.
open -a Hammerspoon 2>/dev/null || true
# Give Hammerspoon some time to start up
sleep 3

# Verify if Hammerspoon is running after the restart attempt
if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "${COMPONENT_NAME} keyboard integration configured successfully."
  ui_info "The keyboard integration should now be active."
else
  ui_warning "Failed to confirm Hammerspoon is running after restart. Please check Hammerspoon manually to ensure it started correctly and its configuration is loaded."
fi
