#!/usr/bin/env bash

# Hammerspoon component cleanup script
# This script is executed when the hammerspoon component is being uninstalled

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Hammerspoon cleanup..."

if pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "  ⏹️  Stopping Hammerspoon..."
  osascript -e 'tell application "Hammerspoon" to quit'
  sleep 2
fi

if command -v osascript >/dev/null 2>&1; then
  ui_info "  🗑️  Removing Hammerspoon from login items..."
  osascript -e '
    tell application "System Events"
        try
            delete login item "Hammerspoon"
        end try
    end tell
    ' 2>/dev/null || true
fi

local_hammerspoon_dir="$HOME/.hammerspoon"
if [[ -d "$local_hammerspoon_dir" ]]; then
  ui_info "  📝 Cleaning up Hammerspoon logs..."
  find "$local_hammerspoon_dir" -name "*.log" -delete 2>/dev/null || true
fi

ui_success "✅ Hammerspoon cleanup completed"
