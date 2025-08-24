#!/usr/bin/env bash

# JavaScript Development component cleanup script
# This script is executed when the js-development component is being uninstalled

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running JavaScript Development cleanup..."

if command -v npm >/dev/null 2>&1; then
  ui_info "  📦 Cleaning npm cache..."
  npm cache clean --force 2>/dev/null || true
fi

if [[ -d "$HOME/.tscache" ]]; then
  ui_info "  🗑️  Removing TypeScript cache..."
  rm -rf "$HOME/.tscache" || true
fi

if [[ -d "$HOME/.npm-global" ]]; then
  ui_info "  🗑️  Cleaning up global npm packages cache..."
  rm -rf "$HOME/.npm-global/lib/node_modules/.cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.eslintcache" ]]; then
  ui_info "  🗑️  Removing ESLint cache..."
  rm -rf "$HOME/.eslintcache" || true
fi

ui_success "✅ JavaScript Development cleanup completed"
