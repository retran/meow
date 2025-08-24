#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Gaming cleanup..."

if pgrep -f "Steam" >/dev/null; then
  ui_info "  ⏹️  Stopping Steam..."
  osascript -e 'tell application "Steam" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "GeForce NOW" >/dev/null; then
  ui_info "  ⏹️  Stopping NVIDIA GeForce NOW..."
  osascript -e 'tell application "GeForce NOW" to quit' 2>/dev/null || true
  sleep 2
fi

if command -v osascript >/dev/null 2>&1; then
  ui_info "  🗑️  Removing gaming apps from login items..."
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

ui_info "  🗑️  Cleaning gaming cache and logs..."
if [[ -d "$HOME/Library/Logs/Steam" ]]; then
  rm -rf "$HOME/Library/Logs/Steam" 2>/dev/null || true
fi

ui_success "✅ Gaming cleanup completed"
ui_info "ℹ️  Note: Game saves and user data were preserved"
