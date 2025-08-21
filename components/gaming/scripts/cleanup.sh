#!/usr/bin/env bash

# Gaming component cleanup script
# This script is executed when the gaming component is being uninstalled

set -euo pipefail

echo "🧹 Running Gaming cleanup..."

# Stop Steam if it's running
if pgrep -f "Steam" >/dev/null; then
  echo "  ⏹️  Stopping Steam..."
  osascript -e 'tell application "Steam" to quit' 2>/dev/null || true
  sleep 2
fi

# Stop NVIDIA GeForce NOW if it's running
if pgrep -f "GeForce NOW" >/dev/null; then
  echo "  ⏹️  Stopping NVIDIA GeForce NOW..."
  osascript -e 'tell application "GeForce NOW" to quit' 2>/dev/null || true
  sleep 2
fi

# Remove gaming apps from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "  🗑️  Removing gaming apps from login items..."
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
echo "  🗑️  Cleaning gaming cache and logs..."
if [[ -d "$HOME/Library/Logs/Steam" ]]; then
  rm -rf "$HOME/Library/Logs/Steam" 2>/dev/null || true
fi

echo "✅ Gaming cleanup completed"
echo "ℹ️  Note: Game saves and user data were preserved"
