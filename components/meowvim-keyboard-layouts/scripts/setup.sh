#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/meowvim-keyboard-layouts/scripts/setup.sh
# @brief: Setup script for vim keyboard layout switching configuration.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

case "$OSTYPE" in
  darwin*) ;;
  *)
    ui_warning "This script is intended for macOS only. Exiting."
    exit 0
    ;;
esac

if ! [ -d "/Applications/Hammerspoon.app" ] && ! command -v hs >/dev/null 2>&1; then
  ui_warning "Hammerspoon is required for ${COMPONENT_NAME}. Please install it (e.g., via Homebrew) and ensure it's in /Applications or its 'hs' command is in your PATH. Exiting."
  exit 0
fi

ui_action_start "Configuring ${COMPONENT_NAME} keyboard integration..."

ui_info "Attempting to restart Hammerspoon to apply changes..."

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "Stopping existing Hammerspoon process..."
  osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  sleep 2
fi

ui_info "Starting Hammerspoon..."
open -a Hammerspoon 2>/dev/null || true
sleep 3

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "${COMPONENT_NAME} keyboard integration configured successfully."
  ui_info "The keyboard integration should now be active."
else
  ui_warning "Failed to confirm Hammerspoon is running after restart. Please check Hammerspoon manually to ensure it started correctly and its configuration is loaded."
fi
