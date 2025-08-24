#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "corporate_cleanup_running")"

if pgrep -f "Slack" >/dev/null; then
  ui_info "$(fmt "corporate_stopping_slack")"
  pkill -f "Slack" 2>/dev/null || true
  sleep 2
fi

if pgrep -f "zoom" >/dev/null; then
  ui_info "$(fmt "corporate_stopping_zoom")"
  pkill -f "zoom" 2>/dev/null || true
  sleep 2
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "$(fmt "corporate_removing_login_items")"

  osascript -e 'tell application "System Events" to delete login item "Slack"' 2>/dev/null || true

  osascript -e 'tell application "System Events" to delete login item "zoom.us"' 2>/dev/null || true
  osascript -e 'tell application "System Events" to delete login item "Zoom"' 2>/dev/null || true
fi

ui_info "$(fmt "corporate_cleaning_cache")"

rm -rf "$HOME/Library/Logs/Slack" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.tinyspeck.slackmacgap" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/ZoomPhone" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/zoom.us" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/us.zoom.xos" 2>/dev/null || true

ui_success "$(fmt "corporate_cleanup_completed")"
