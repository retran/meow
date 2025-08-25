#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Node cleanup..."

if command -v npm >/dev/null 2>&1; then
  ui_info "  📦 Cleaning npm cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  📝 (dry-run) Would run: npm cache clean --force"
  else
    npm cache clean --force 2>/dev/null || true
  fi
fi

if command -v yarn >/dev/null 2>&1; then
  ui_info "  📦 Cleaning yarn cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  📝 (dry-run) Would run: yarn cache clean"
  else
    yarn cache clean 2>/dev/null || true
  fi
fi

if command -v pnpm >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pnpm store..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  📝 (dry-run) Would run: pnpm store prune"
  else
    pnpm store prune 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.npm/_cacache" ]; then
  ui_info "  🗑️  Cleaning npm global cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  📝 (dry-run) Would remove: $HOME/.npm/_cacache"
  else
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || ui_error "Failed to remove npm cache directory"
  fi
fi

if [ -d "$HOME/.node-gyp" ]; then
  ui_info "  🗑️  Cleaning node-gyp cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  📝 (dry-run) Would remove: $HOME/.node-gyp"
  else
    rm -rf "$HOME/.node-gyp" 2>/dev/null || ui_error "Failed to remove node-gyp cache directory"
  fi
fi

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "Verbose mode enabled"
fi

ui_success "✅ Node cleanup completed"
