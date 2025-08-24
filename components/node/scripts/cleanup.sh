#!/usr/bin/env bash

# Node component cleanup script
# This script is executed when the node component is being uninstalled

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Node cleanup..."

if command -v npm >/dev/null 2>&1; then
  ui_info "  📦 Cleaning npm cache..."
  npm cache clean --force 2>/dev/null || true
fi

if command -v yarn >/dev/null 2>&1; then
  ui_info "  📦 Cleaning yarn cache..."
  yarn cache clean 2>/dev/null || true
fi

if command -v pnpm >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pnpm cache..."
  pnpm store prune 2>/dev/null || true
fi

if [[ -d "$HOME/.npm" ]]; then
  ui_info "  🗑️  Cleaning npm global cache..."
  rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
fi

if [[ -d "$HOME/.node-gyp" ]]; then
  ui_info "  🗑️  Cleaning node-gyp cache..."
  rm -rf "$HOME/.node-gyp" 2>/dev/null || true
fi

ui_success "✅ Node cleanup completed"
