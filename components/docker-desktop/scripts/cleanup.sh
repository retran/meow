#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running OrbStack cleanup..."

if pgrep -f "OrbStack" >/dev/null; then
  ui_info "  ⏹️  Stopping OrbStack..."
  osascript -e 'tell application "OrbStack" to quit' 2>/dev/null || true
  sleep 3
fi

if command -v orb >/dev/null 2>&1; then
  ui_info "  🐳 Stopping running machines..."
  orb stop --all 2>/dev/null || true
  sleep 2
fi

if command -v docker >/dev/null 2>&1; then
  ui_info "  🗑️  Cleaning up Docker networks and volumes..."
  docker system prune -af --volumes 2>/dev/null || true
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "  🗑️  Removing OrbStack from login items..."
  osascript -e 'tell application "System Events" to delete login item "OrbStack"' 2>/dev/null || true
fi

ui_success "✅ OrbStack cleanup completed"
ui_info "ℹ️  Note: Docker images and containers have been cleaned up"
ui_info "ℹ️  Note: To fully remove OrbStack data, manually delete ~/Library/Application Support/OrbStack"
