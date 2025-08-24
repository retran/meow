#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Docker CLI cleanup..."

if command -v docker >/dev/null 2>&1; then
  ui_info "  🗑️  Cleaning Docker system cache..."

  docker system prune -f 2>/dev/null || true

  docker builder prune -f 2>/dev/null || true
fi

if [[ -d "$HOME/.docker" ]]; then
  ui_info "  🗑️  Cleaning Docker configuration cache..."
  rm -f "$HOME/.docker/config.json.backup" 2>/dev/null || true
  rm -rf "$HOME/.docker/cli-plugins/cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.docker/compose" ]]; then
  ui_info "  🗑️  Cleaning Docker Compose cache..."
  rm -rf "$HOME/.docker/compose/cache" 2>/dev/null || true
fi

ui_success "✅ Docker CLI cleanup completed"
