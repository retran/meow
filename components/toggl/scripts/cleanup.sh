#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "Starting Toggl cleanup process..."

if [[ -d "$HOME/.toggl" ]]; then
  ui_info "Cleaning Toggl configuration cache and log files in '$HOME/.toggl'..."
  rm -rf "$HOME/.toggl/cache" 2>/dev/null || true
  rm -f "$HOME/.toggl/toggl.log" 2>/dev/null || true
fi

ui_info "Cleaning temporary Toggl files from '/tmp' and '$HOME'..."
rm -f "/tmp/toggl_*" 2>/dev/null || true
rm -f "$HOME/.toggl_tmp_*" 2>/dev/null || true

ui_info "Toggl API data and user settings are preserved."

ui_success "Toggl cleanup completed successfully."
