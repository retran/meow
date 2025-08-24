#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Go Development cleanup..."

if command -v go >/dev/null 2>&1; then
  ui_info "  📦 Cleaning Go module cache..."
  go clean -modcache 2>/dev/null || true

  ui_info "  🗑️  Cleaning Go build cache..."
  go clean -cache 2>/dev/null || true

  ui_info "  🗑️  Cleaning Go test cache..."
  go clean -testcache 2>/dev/null || true
fi

if [[ -f "$HOME/go.work" ]]; then
  ui_info "  🗑️  Removing Go workspace file..."
  rm -f "$HOME/go.work" || true
fi

if [[ -n "${GOPATH:-}" && -d "$GOPATH/pkg" ]]; then
  ui_info "  🗑️  Cleaning GOPATH pkg directory..."
  rm -rf "$GOPATH/pkg" 2>/dev/null || true
fi

ui_success "✅ Go Development cleanup completed"
