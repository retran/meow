#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Pipx cleanup..."

if command -v pipx >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pipx cache..."
  pipx uninstall-all --force 2>/dev/null || true
fi

if [[ -d "$HOME/.local/share/pipx" ]]; then
  ui_info "  🗑️  Cleaning pipx installation directory..."
  rm -rf "$HOME/.local/share/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.cache/pipx" ]]; then
  ui_info "  🗑️  Cleaning pipx cache directory..."
  rm -rf "$HOME/.cache/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/bin" ]]; then
  ui_info "  🗑️  Cleaning pipx binaries..."
  find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; 2>/dev/null || true
fi

ui_success "✅ Pipx cleanup completed"
