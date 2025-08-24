#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Media cleanup..."

if pgrep -f "OBS" >/dev/null; then
  ui_info "  ⏹️  Stopping OBS Studio..."
  osascript -e 'tell application "OBS" to quit' 2>/dev/null || true
  sleep 2
fi

if command -v osascript >/dev/null 2>&1; then
  ui_info "  🗑️  Removing media apps from login items..."
  osascript -e '
    tell application "System Events"
        try
            delete login item "OBS"
        end try
    end tell
    ' 2>/dev/null || true
fi

ui_info "  🗑️  Cleaning media app cache and logs..."
if [[ -d "$HOME/Library/Application Support/obs-studio/logs" ]]; then
  rm -rf "$HOME/Library/Application Support/obs-studio/logs" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/OBS" ]]; then
  rm -rf "$HOME/Library/Logs/OBS" 2>/dev/null || true
fi

ui_success "✅ Media cleanup completed"
ui_info "ℹ️  Note: User recordings and scenes were preserved"
