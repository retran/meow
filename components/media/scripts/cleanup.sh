#!/usr/bin/env bash

# Media component cleanup script
# This script is executed when the media component is being uninstalled

set -euo pipefail

echo "🧹 Running Media cleanup..."

# Stop OBS Studio if it's running
if pgrep -f "OBS" > /dev/null; then
    echo "  ⏹️  Stopping OBS Studio..."
    osascript -e 'tell application "OBS" to quit' 2>/dev/null || true
    sleep 2
fi

# Remove media apps from login items (if present)
if command -v osascript >/dev/null 2>&1; then
    echo "  🗑️  Removing media apps from login items..."
    osascript -e '
    tell application "System Events"
        try
            delete login item "OBS"
        end try
    end tell
    ' 2>/dev/null || true
fi

# Clean up OBS cache and logs
echo "  🗑️  Cleaning media app cache and logs..."
if [[ -d "$HOME/Library/Application Support/obs-studio/logs" ]]; then
    rm -rf "$HOME/Library/Application Support/obs-studio/logs" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/OBS" ]]; then
    rm -rf "$HOME/Library/Logs/OBS" 2>/dev/null || true
fi

echo "✅ Media cleanup completed"
echo "ℹ️  Note: User recordings and scenes were preserved"
