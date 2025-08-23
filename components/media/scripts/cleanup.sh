#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "media_cleanup_running")"

if pgrep -f "OBS" >/dev/null; then
  ui_info "$(get_static_message "media_stopping_obs")"
  osascript -e 'tell application "OBS" to quit' 2>/dev/null || true
  sleep 2
fi

if command -v osascript >/dev/null 2>&1; then
  ui_info "$(get_static_message "media_removing_login_items")"
  osascript -e '
    tell application "System Events"
        try
            delete login item "OBS"
        end try
    end tell
    ' 2>/dev/null || true
fi

ui_info "$(get_static_message "media_cleaning_cache")"
if [[ -d "$HOME/Library/Application Support/obs-studio/logs" ]]; then
  rm -rf "$HOME/Library/Application Support/obs-studio/logs" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/OBS" ]]; then
  rm -rf "$HOME/Library/Logs/OBS" 2>/dev/null || true
fi

ui_success "$(get_static_message "media_cleanup_completed")"
ui_info "$(get_static_message "media_user_recordings_preserved")"
