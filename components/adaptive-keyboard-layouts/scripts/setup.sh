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
# @file: components/adaptive-keyboard-layouts/scripts/setup.sh
# @brief: Setup script for adaptive keyboard layout management system.
# @author: Andrew Vasilyev
# @license: MIT
#
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

if [ "${MEOW_VERBOSE}" = "true" ]; then
  ui_info "Checking if Hammerspoon is running..."
fi

if pgrep -x "Hammerspoon" >/dev/null; then
  if [ "${MEOW_VERBOSE}" = "true" ]; then
    ui_info "Stopping Hammerspoon..."
  fi
  if [ "${MEOW_DRY_RUN}" != "true" ]; then
    osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
  fi
  sleep 2
fi

if [ "${MEOW_VERBOSE}" = "true" ]; then
  ui_info "Starting Hammerspoon..."
fi

if [ "${MEOW_DRY_RUN}" != "true" ]; then
  open -a Hammerspoon 2>/dev/null || true
fi

sleep 3

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_action_success "Adaptive Keyboard configured successfully."
else
  if [ "${MEOW_VERBOSE}" = "true" ]; then
    ui_warning "Failed to restart Hammerspoon. Please ensure Hammerspoon is installed and running correctly."
  fi
fi
