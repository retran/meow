#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "orbstack_cleanup_running")"

if pgrep -f "OrbStack" >/dev/null; then
  ui_info "$(fmt "orbstack_stopping_app")"
  osascript -e 'tell application "OrbStack" to quit' 2>/dev/null || true
  sleep 3
fi

if command -v orb >/dev/null 2>&1; then
  ui_info "$(fmt "orbstack_stopping_machines")"
  orb stop --all 2>/dev/null || true
  sleep 2
fi

if command -v docker >/dev/null 2>&1; then
  ui_info "$(fmt "orbstack_cleaning_networks_volumes")"
  docker system prune -af --volumes 2>/dev/null || true
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "$(fmt "orbstack_removing_login_items")"
  osascript -e 'tell application "System Events" to delete login item "OrbStack"' 2>/dev/null || true
fi

ui_success "$(fmt "orbstack_cleanup_completed")"
ui_info "$(fmt "orbstack_images_containers_cleaned")"
ui_info "$(fmt "orbstack_manual_removal_note")"
