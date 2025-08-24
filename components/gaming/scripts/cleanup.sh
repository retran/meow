#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "gaming_cleanup_running")"

if pgrep -f "Steam" >/dev/null; then
  ui_info "$(fmt "gaming_stopping_steam")"
  osascript -e 'tell application "Steam" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "GeForce NOW" >/dev/null; then
  ui_info "$(fmt "gaming_stopping_geforce_now")"
  osascript -e 'tell application "GeForce NOW" to quit' 2>/dev/null || true
  sleep 2
fi

if command -v osascript >/dev/null 2>&1; then
  ui_info "$(fmt "gaming_removing_login_items")"
  osascript -e '
    tell application "System Events"
        try
            delete login item "Steam"
        end try
        try
            delete login item "GeForce NOW"
        end try
    end tell
    ' 2>/dev/null || true
fi

ui_info "$(fmt "gaming_cleaning_cache")"
if [[ -d "$HOME/Library/Logs/Steam" ]]; then
  rm -rf "$HOME/Library/Logs/Steam" 2>/dev/null || true
fi

ui_success "$(fmt "gaming_cleanup_completed")"
ui_info "$(fmt "gaming_saves_preserved")"
