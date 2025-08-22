#!/usr/bin/env bash

# Gaming component cleanup script
# This script is executed when the gaming component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "gaming_cleanup_running")"

# Stop Steam if it's running
if pgrep -f "Steam" >/dev/null; then
  echo "$(get_static_message "gaming_stopping_steam")"
  osascript -e 'tell application "Steam" to quit' 2>/dev/null || true
  sleep 2
fi

# Stop NVIDIA GeForce NOW if it's running
if pgrep -f "GeForce NOW" >/dev/null; then
  echo "$(get_static_message "gaming_stopping_geforce_now")"
  osascript -e 'tell application "GeForce NOW" to quit' 2>/dev/null || true
  sleep 2
fi

# Remove gaming apps from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "$(get_static_message "gaming_removing_login_items")"
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

# Clean up gaming-related temporary files
echo "$(get_static_message "gaming_cleaning_cache")"
if [[ -d "$HOME/Library/Logs/Steam" ]]; then
  rm -rf "$HOME/Library/Logs/Steam" 2>/dev/null || true
fi

echo "$(get_static_message "gaming_cleanup_completed")"
echo "$(get_static_message "gaming_saves_preserved")"
