#!/usr/bin/env bash

# Media component cleanup script
# This script is executed when the media component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "media_cleanup_running")"

# Stop OBS Studio if it's running
if pgrep -f "OBS" >/dev/null; then
  echo "$(get_static_message "media_stopping_obs")"
  osascript -e 'tell application "OBS" to quit' 2>/dev/null || true
  sleep 2
fi

# Remove media apps from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "$(get_static_message "media_removing_login_items")"
  osascript -e '
    tell application "System Events"
        try
            delete login item "OBS"
        end try
    end tell
    ' 2>/dev/null || true
fi

# Clean up OBS cache and logs
echo "$(get_static_message "media_cleaning_cache")"
if [[ -d "$HOME/Library/Application Support/obs-studio/logs" ]]; then
  rm -rf "$HOME/Library/Application Support/obs-studio/logs" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/OBS" ]]; then
  rm -rf "$HOME/Library/Logs/OBS" 2>/dev/null || true
fi

echo "$(get_static_message "media_cleanup_completed")"
echo "$(get_static_message "media_user_recordings_preserved")"
