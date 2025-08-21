#!/usr/bin/env bash

# Hammerspoon component cleanup script
# This script is executed when the hammerspoon component is being uninstalled

set -euo pipefail

# Arguments (for future use if needed)
# component_name="$1"
# meow_dir="$2"

echo "🧹 Running Hammerspoon cleanup..."

# Stop Hammerspoon if it's running
if pgrep -x "Hammerspoon" > /dev/null; then
    echo "  ⏹️  Stopping Hammerspoon..."
    osascript -e 'tell application "Hammerspoon" to quit'
    sleep 2
fi

# Remove Hammerspoon from login items (if present)
if command -v osascript >/dev/null 2>&1; then
    echo "  🗑️  Removing Hammerspoon from login items..."
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
    echo "  📝 Cleaning up Hammerspoon logs..."
    find "$local_hammerspoon_dir" -name "*.log" -delete 2>/dev/null || true
fi

echo "✅ Hammerspoon cleanup completed"
