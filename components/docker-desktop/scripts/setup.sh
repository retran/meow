#!/usr/bin/env bash

set -euo pipefail
source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "orbstack_setup_running")"

if ! command -v orb >/dev/null 2>&1; then
  ui_warning "OrbStack CLI not found. Installation may not be complete."
  exit 1
fi

if ! pgrep -f "OrbStack" >/dev/null; then
  ui_info "$(fmt "orbstack_starting_app")"
  open -a OrbStack 2>/dev/null || true

  ui_info "$(fmt "orbstack_waiting_for_startup")"
  local attempts=0
  while ! orb status >/dev/null 2>&1 && [[ $attempts -lt 30 ]]; do
    sleep 2
    ((attempts++))
  done

  if [[ $attempts -eq 30 ]]; then
    ui_warning "OrbStack startup timed out. Please start it manually."
    exit 1
  fi
fi

ui_success "$(fmt "orbstack_setup_completed")"
ui_info "$(fmt "orbstack_ready_to_use")"
