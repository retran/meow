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
# @file: lib/core/session.sh
# @brief: Session management and state tracking utilities.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_CORE_SESSION_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_SESSION_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/tools.sh"

_initialize_session() {
  if [ "$IS_ALPINE" = "true" ]; then
    ui_spinner "Initializing Alpine Linux setup..." setup_apk ""
  elif [ "$IS_DEBIAN_BASED" = "true" ]; then
    ui_spinner "Initializing Debian/Ubuntu setup..." setup_apt ""
  elif [ "$IS_RPM_BASED" = "true" ]; then
    ui_spinner "Initializing RPM setup..." setup_dnf ""
  elif [ "$IS_ARCH" = "true" ]; then
    ui_spinner "Initializing Arch Linux setup..." setup_pacman ""
  elif [ "$IS_MACOS" = "true" ]; then
    ui_spinner "Initializing macOS Homebrew setup..." setup_homebrew ""
  else
    ui_action_warning "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  if ! ensure_yq; then
    ui_action_error "Failed to ensure yq installation."
    return 1
  fi
}

_finalize_session() {
  if [ "$IS_ALPINE" = "true" ]; then
    cleanup_apk ""
  elif [ "$IS_DEBIAN_BASED" = "true" ]; then
    cleanup_apt ""
  elif [ "$IS_RPM_BASED" = "true" ]; then
    cleanup_dnf ""
  elif [ "$IS_ARCH" = "true" ]; then
    cleanup_pacman ""
  elif [ "$IS_MACOS" = "true" ]; then
    cleanup_homebrew ""
  fi
}
