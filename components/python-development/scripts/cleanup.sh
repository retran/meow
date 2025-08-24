#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Python Development cleanup..."

if command -v pip >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pip cache..."
  pip cache purge 2>/dev/null || true
fi

if command -v pip3 >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pip3 cache..."
  pip3 cache purge 2>/dev/null || true
fi

ui_info "  🗑️  Cleaning Python bytecode files..."
find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

if [[ -d "$HOME/.pytest_cache" ]]; then
  ui_info "  🗑️  Removing pytest cache..."
  rm -rf "$HOME/.pytest_cache" || true
fi

if [[ -d "$HOME/.mypy_cache" ]]; then
  ui_info "  🗑️  Removing mypy cache..."
  rm -rf "$HOME/.mypy_cache" || true
fi

if [[ -d "$HOME/.ipython" ]]; then
  ui_info "  🗑️  Cleaning IPython cache..."
  find "$HOME/.ipython" -name "*.pyc" -delete 2>/dev/null || true
  find "$HOME/.ipython" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
fi

ui_success "✅ Python Development cleanup completed"
