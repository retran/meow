#!/usr/bin/env bash
# @file:    components/meowvim/scripts/cleanup.sh
# @brief:   Installation or configuration script for meowvim component.
# @author:  Andrew Vasilyev
# @license: MIT
#

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Meowvim cleanup..."

if [ -d "$HOME/.local/share/nvim" ]; then
  ui_info "  🗑️  Cleaning Neovim cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  ⚠️  Dry run: would remove $HOME/.local/share/nvim"
  else
    rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.local/state/nvim" ]; then
  ui_info "  🗑️  Cleaning Neovim state files..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  ⚠️  Dry run: would remove $HOME/.local/state/nvim"
  else
    rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.vim/tmp" ]; then
  ui_info "  🗑️  Cleaning Vim temporary files..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  ⚠️  Dry run: would remove $HOME/.vim/tmp"
  else
    rm -rf "$HOME/.vim/tmp" 2>/dev/null || true
  fi
fi

ui_info "  🗑️  Cleaning Vim/Neovim swap files..."

if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
  ui_info "  ⚠️  Dry run: would delete swap files"
else
  find "$HOME" -name ".*.swp" -delete 2>/dev/null || true
  find "$HOME" -name ".*.swo" -delete 2>/dev/null || true
  find "$HOME" -name ".*.un~" -delete 2>/dev/null || true
  find "$HOME" -name "*~" -maxdepth 1 -delete 2>/dev/null || true
fi

if [ -d "$HOME/.local/share/nvim/lazy" ]; then
  ui_info "  🗑️  Cleaning Lazy.nvim cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  ⚠️  Dry run: would remove $HOME/.local/share/nvim/lazy"
  else
    rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.local/share/nvim/site/pack/packer" ]; then
  ui_info "  🗑️  Cleaning Packer cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  ⚠️  Dry run: would remove $HOME/.local/share/nvim/site/pack/packer"
  else
    rm -rf "$HOME/.local/share/nvim/site/pack/packer" 2>/dev/null || true
  fi
fi

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "  ✅ Meowvim cleanup completed"
else
  ui_success "✅ Meowvim cleanup completed"
fi
