#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/meowvim/scripts/cleanup.sh
# @brief: Cleanup script for removing meowvim configuration and temporary files.
# @author: Andrew Vasilyev
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
