#!/usr/bin/env bash

# Corporate Communication component cleanup script
# This script is executed when the corporate-communication component is being uninstalled

set -euo pipefail

echo "🧹 Running Corporate Communication cleanup..."

# Stop Slack if it's running
if pgrep -f "Slack" >/dev/null; then
  echo "  ⏹️  Stopping Slack..."
  osascript -e 'tell application "Slack" to quit' 2>/dev/null || true
  sleep 2
fi

# Stop Zoom if it's running
if pgrep -f "zoom.us" >/dev/null; then
  echo "  ⏹️  Stopping Zoom..."
  osascript -e 'tell application "zoom.us" to quit' 2>/dev/null || true
  sleep 2
fi

# Remove corporate apps from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "  🗑️  Removing corporate apps from login items..."
  osascript -e '
    tell application "System Events"
        try
            delete login item "Slack"
        end try
        try
            delete login item "zoom.us"
        end try
    end tell
    ' 2>/dev/null || true
fi

# Clean up application logs and cache
echo "  🗑️  Cleaning corporate app cache and logs..."
if [[ -d "$HOME/Library/Logs/Slack" ]]; then
  rm -rf "$HOME/Library/Logs/Slack" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/ZoomPhone" ]]; then
  rm -rf "$HOME/Library/Logs/ZoomPhone" 2>/dev/null || true
fi

# Clean up temporary files
if [[ -d "/tmp/slack-downloads" ]]; then
  rm -rf "/tmp/slack-downloads" 2>/dev/null || true
fi

echo "✅ Corporate Communication cleanup completed"
echo "ℹ️  Note: User data and settings were preserved"
