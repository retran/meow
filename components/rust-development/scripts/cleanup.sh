#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "rust_dev_cleanup_running")"

if command -v cargo >/dev/null 2>&1; then
  ui_info "$(get_static_message "rust_dev_cleaning_cargo_cache")"
  cargo cache --autoclean 2>/dev/null || true

  ui_info "$(get_static_message "rust_dev_cleaning_registry_cache")"
  if [[ -d "$HOME/.cargo/registry" ]]; then
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
  fi

  ui_info "$(get_static_message "rust_dev_cleaning_git_cache")"
  if [[ -d "$HOME/.cargo/git" ]]; then
    rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
  fi
fi

ui_info "$(get_static_message "rust_dev_cleaning_target_dirs")"
find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

if [[ -d "$HOME/.rustup/tmp" ]]; then
  ui_info "$(get_static_message "rust_dev_cleaning_rustup_temp")"
  rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
fi

ui_success "$(get_static_message "rust_dev_cleanup_completed")"
