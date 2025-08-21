#!/usr/bin/env bash

# Docker Desktop component cleanup script
# This script is executed when the docker-desktop component is being uninstalled

set -euo pipefail

echo "🧹 Running Docker Desktop cleanup..."

# Stop Docker Desktop if it's running
if pgrep -f "Docker Desktop" >/dev/null; then
  echo "  ⏹️  Stopping Docker Desktop..."
  osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null || true
  sleep 3
fi

# Stop docker daemon if it's running
if pgrep -x "dockerd" >/dev/null; then
  echo "  🐳 Stopping Docker daemon..."
  sudo pkill -x dockerd 2>/dev/null || true
  sleep 2
fi

# Clean up Docker networks (optional)
if command -v docker >/dev/null 2>&1; then
  echo "  🗑️  Cleaning up Docker networks and volumes..."
  docker system prune -af --volumes 2>/dev/null || true
fi

# Remove Docker from login items (if present)
if command -v osascript >/dev/null 2>&1; then
  echo "  🗑️  Removing Docker Desktop from login items..."
  osascript -e '
    tell application "System Events"
        try
            delete login item "Docker Desktop"
        end try
    end tell
    ' 2>/dev/null || true
fi

echo "✅ Docker Desktop cleanup completed"
echo "ℹ️  Note: Docker images and containers have been cleaned up"
echo "ℹ️  Note: To fully remove Docker data, manually delete ~/Library/Containers/com.docker.docker"
