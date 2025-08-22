#!/usr/bin/env bash

# Pipx component cleanup script
# This script is executed when the pipx component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "pipx_cleanup_running")"

# Clean up pipx cache
if command -v pipx >/dev/null 2>&1; then
  echo "$(get_static_message "pipx_cleaning_cache")"
  pipx uninstall-all --force 2>/dev/null || true
fi

# Clean up pipx directories
if [[ -d "$HOME/.local/share/pipx" ]]; then
  echo "$(get_static_message "pipx_cleaning_installation_dir")"
  rm -rf "$HOME/.local/share/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.cache/pipx" ]]; then
  echo "$(get_static_message "pipx_cleaning_cache_dir")"
  rm -rf "$HOME/.cache/pipx" 2>/dev/null || true
fi

# Clean up pipx bin directory from PATH (if it exists)
if [[ -d "$HOME/.local/bin" ]]; then
  echo "$(get_static_message "pipx_cleaning_binaries")"
  # Only remove pipx-installed binaries, keep other user binaries
  find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; 2>/dev/null || true
fi

echo "$(get_static_message "pipx_cleanup_completed")"
