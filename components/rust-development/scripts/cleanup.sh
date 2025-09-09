#!/usr/bin/env bash
# @file:    components/rust-development/scripts/cleanup.sh
# @brief:   Cleanup script for removing Rust development tools and temporary files.
# @author:  Andrew Vasilyev
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
