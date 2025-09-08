#!/usr/bin/env bash

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
