#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Rust Development cleanup..."

if command -v cargo >/dev/null 2>&1; then
  ui_info "  📦 Cleaning cargo cache..."
  cargo cache --autoclean 2>/dev/null || true

  ui_info "  🗑️  Cleaning cargo registry cache..."
  if [[ -d "$HOME/.cargo/registry" ]]; then
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
  fi

  ui_info "  🗑️  Cleaning cargo git cache..."
  if [[ -d "$HOME/.cargo/git" ]]; then
    rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
  fi
fi

ui_info "  🗑️  Cleaning Rust target directories..."
find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

if [[ -d "$HOME/.rustup/tmp" ]]; then
  ui_info "  🗑️  Cleaning rustup temporary files..."
  rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
fi

ui_success "✅ Rust Development cleanup completed"
