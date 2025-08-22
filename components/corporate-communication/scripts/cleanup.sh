#!/usr/bin/env bash

# Corporate Communication component cleanup script
# This script is executed when the corporate-communication component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "corporate_cleanup_running")"

# Stop Slack if running
if pgrep -f "Slack" >/dev/null; then
  echo "$(get_static_message "corporate_stopping_slack")"
  pkill -f "Slack" 2>/dev/null || true
  sleep 2
fi

# Stop Zoom if running
if pgrep -f "zoom" >/dev/null; then
  echo "$(get_static_message "corporate_stopping_zoom")"
  pkill -f "zoom" 2>/dev/null || true
  sleep 2
fi

# Remove corporate apps from login items (macOS specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "$(get_static_message "corporate_removing_login_items")"

  # Remove Slack from login items
  osascript -e 'tell application "System Events" to delete login item "Slack"' 2>/dev/null || true

  # Remove Zoom from login items
  osascript -e 'tell application "System Events" to delete login item "zoom.us"' 2>/dev/null || true
  osascript -e 'tell application "System Events" to delete login item "Zoom"' 2>/dev/null || true

  # Remove Microsoft Teams from login items
  osascript -e 'tell application "System Events" to delete login item "Microsoft Teams"' 2>/dev/null || true
fi

echo "$(get_static_message "corporate_cleaning_cache")"

# Clean up corporate app caches and logs
rm -rf "$HOME/Library/Logs/Slack" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.tinyspeck.slackmacgap" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/ZoomPhone" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/zoom.us" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/us.zoom.xos" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/Microsoft Teams" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.microsoft.teams" 2>/dev/null || true

echo "$(get_static_message "corporate_cleanup_completed")"
