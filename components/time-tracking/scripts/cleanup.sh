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
# @file: components/time-tracking/scripts/cleanup.sh
# @brief: Cleanup script for removing time tracking tools and temporary data.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

ui_info "Starting Toggl cleanup process..."

if [ -d "$HOME/.toggl" ]; then
  ui_info "Cleaning Toggl configuration cache and log files in '$HOME/.toggl'..."
  if [ -n "${MEOW_DRY_RUN:-}" ] && [ "${MEOW_DRY_RUN}" = "true" ]; then
    ui_info "DRY-RUN: Would remove '$HOME/.toggl/cache'"
    ui_info "DRY-RUN: Would remove '$HOME/.toggl/toggl.log'"
  else
    rm -rf "$HOME/.toggl/cache" 2>/dev/null || true
    rm -f "$HOME/.toggl/toggl.log" 2>/dev/null || true
  fi
fi

if [ -n "${MEOW_DRY_RUN:-}" ] && [ "${MEOW_DRY_RUN}" = "true" ]; then
  ui_info "DRY-RUN: Would remove '/tmp/toggl_*'"
  ui_info "DRY-RUN: Would remove '$HOME/.toggl_tmp_*'"
else
  rm -f "/tmp/toggl_*" 2>/dev/null || true
  rm -f "$HOME/.toggl_tmp_*" 2>/dev/null || true
fi

ui_info "Toggl API data and user settings are preserved."

if [ -n "${MEOW_VERBOSE:-}" ] && [ "${MEOW_VERBOSE}" = "true" ]; then
  ui_info "Verbose mode enabled: cleanup completed"
fi

ui_success "Toggl cleanup completed successfully."
