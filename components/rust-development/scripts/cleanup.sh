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
# @file: components/rust-development/scripts/cleanup.sh
# @brief: Cleanup script for removing Rust development tools and temporary files.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Rust Development cleanup..."

if command -v cargo >/dev/null 2>&1; then
  ui_info "  📦 Cleaning cargo cache..."
  if [ "${MEOW_VERBOSE}" = "true" ]; then
    cargo cache --autoclean
  else
    cargo cache --autoclean 2>/dev/null || true
  fi

  ui_info "  🗑️  Cleaning cargo registry cache..."
  if [ -d "$HOME/.cargo/registry" ]; then
    if [ "${MEOW_DRY_RUN}" = "true" ]; then
      ui_info "  🗃️  Would remove: $HOME/.cargo/registry/cache"
    else
      rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
    fi
  fi

  ui_info "  🗑️  Cleaning cargo git cache..."
  if [ -d "$HOME/.cargo/git" ]; then
    if [ "${MEOW_DRY_RUN}" = "true" ]; then
      ui_info "  🗃️  Would remove: $HOME/.cargo/git/checkouts"
    else
      rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
    fi
  fi
fi

ui_info "  🗑️  Cleaning Rust target directories..."
if [ "${MEOW_DRY_RUN}" = "true" ]; then
  ui_info "  🗃️  Would run: find \"$HOME\" -name \"target\" -type d -path \"*/Cargo.toml\" -prune -o -name \"target\" -type d -exec rm -rf {} +"
else
  find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
fi

if [ -d "$HOME/.rustup/tmp" ]; then
  ui_info "  🗑️  Cleaning rustup temporary files..."
  if [ "${MEOW_DRY_RUN}" = "true" ]; then
    ui_info "  🗃️  Would remove: $HOME/.rustup/tmp"
  else
    rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
  fi
fi

ui_success "✅ Rust Development cleanup completed"
