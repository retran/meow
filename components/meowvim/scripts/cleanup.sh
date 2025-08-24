#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Meowvim cleanup..."

if [[ -d "$HOME/.local/share/nvim" ]]; then
  ui_info "  🗑️  Cleaning Neovim cache..."
  rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/state/nvim" ]]; then
  ui_info "  🗑️  Cleaning Neovim state files..."
  rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
fi

if [[ -d "$HOME/.vim/tmp" ]]; then
  ui_info "  🗑️  Cleaning Vim temporary files..."
  rm -rf "$HOME/.vim/tmp" 2>/dev/null || true
fi

ui_info "  🗑️  Cleaning Vim/Neovim swap files..."

find "$HOME" -name ".*.swp" -delete 2>/dev/null || true
find "$HOME" -name ".*.swo" -delete 2>/dev/null || true
find "$HOME" -name ".*.un~" -delete 2>/dev/null || true
find "$HOME" -name "*~" -maxdepth 1 -delete 2>/dev/null || true

if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ui_info "  🗑️  Cleaning Lazy.nvim cache..."
  rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/share/nvim/site/pack/packer" ]]; then
  ui_info "  🗑️  Cleaning Packer cache..."
  rm -rf "$HOME/.local/share/nvim/site/pack/packer" 2>/dev/null || true
fi

ui_success "✅ Meowvim cleanup completed"
