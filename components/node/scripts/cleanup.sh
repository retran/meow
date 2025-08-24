#!/usr/bin/env bash

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
  ui_info "  📦 Cleaning pnpm store..."
  pnpm store prune 2>/dev/null || true
fi

if [ -d "$HOME/.npm/_cacache" ]; then
  ui_info "  🗑️  Cleaning npm global cache directory..."
  rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
fi

if [ -d "$HOME/.node-gyp" ]; then
  ui_info "  🗑️  Cleaning node-gyp cache directory..."
  rm -rf "$HOME/.node-gyp" 2>/dev/null || true
fi

ui_success "✅ Node cleanup completed"
