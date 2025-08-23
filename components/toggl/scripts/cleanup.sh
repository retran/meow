#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "toggl_cleanup_running")"

if [[ -d "$HOME/.toggl" ]]; then
  ui_info "$(get_static_message "toggl_cleaning_config_cache")"
  rm -rf "$HOME/.toggl/cache" 2>/dev/null || true
  rm -f "$HOME/.toggl/toggl.log" 2>/dev/null || true
fi

ui_info "$(get_static_message "toggl_cleaning_temp_files")"
rm -f "/tmp/toggl_*" 2>/dev/null || true
rm -f "$HOME/.toggl_tmp_*" 2>/dev/null || true

ui_info "$(get_static_message "toggl_preserving_api_data")"

ui_success "$(get_static_message "toggl_cleanup_completed")"
