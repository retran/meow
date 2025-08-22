#!/usr/bin/env bash

# Rust Development component cleanup script
# This script is executed when the rust-development component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "rust_dev_cleanup_running")"

# Clear cargo cache
if command -v cargo >/dev/null 2>&1; then
  echo "$(get_static_message "rust_dev_cleaning_cargo_cache")"
  cargo cache --autoclean 2>/dev/null || true

  echo "$(get_static_message "rust_dev_cleaning_registry_cache")"
  if [[ -d "$HOME/.cargo/registry" ]]; then
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
  fi

  echo "$(get_static_message "rust_dev_cleaning_git_cache")"
  if [[ -d "$HOME/.cargo/git" ]]; then
    rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
  fi
fi

# Clean up target directories in common development locations
echo "$(get_static_message "rust_dev_cleaning_target_dirs")"
find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up Rustup temp files
if [[ -d "$HOME/.rustup/tmp" ]]; then
  echo "$(get_static_message "rust_dev_cleaning_rustup_temp")"
  rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
fi

echo "$(get_static_message "rust_dev_cleanup_completed")"
