#!/usr/bin/env bash

# Hammerspoon component cleanup script
# This script is executed when the hammerspoon component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

# Arguments (for future use if needed)
# component_name="$1"
# meow_dir="$2"

echo "$(get_static_message "hammerspoon_cleanup_running")"

# Stop Hammerspoon if it's running
if pgrep -x "Hammerspoon" >/dev/null; then
  echo "$(get_static_message "hammerspoon_stopping")"
  osascript -e 'tell application "Hammerspoon" to quit'
  sleep 2
fi

# Remove Hammerspoon from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "$(get_static_message "hammerspoon_removing_login_items")"
  osascript -e '
    tell application "System Events"
        try
            delete login item "Hammerspoon"
        end try
    end tell
    ' 2>/dev/null || true
fi

# Clear any Hammerspoon console logs (optional cleanup)
local_hammerspoon_dir="$HOME/.hammerspoon"
if [[ -d "$local_hammerspoon_dir" ]]; then
  echo "$(get_static_message "hammerspoon_cleaning_logs")"
  find "$local_hammerspoon_dir" -name "*.log" -delete 2>/dev/null || true
fi

echo "$(get_static_message "hammerspoon_cleanup_completed")"
