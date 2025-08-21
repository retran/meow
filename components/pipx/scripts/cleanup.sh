#!/usr/bin/env bash

# Pipx component cleanup script
# This script is executed when the pipx component is being uninstalled

set -euo pipefail

echo "🧹 Running Pipx cleanup..."

# Clean up pipx cache
if command -v pipx >/dev/null 2>&1; then
  echo "  📦 Cleaning pipx cache..."
  pipx uninstall-all --force 2>/dev/null || true
fi

# Clean up pipx directories
if [[ -d "$HOME/.local/share/pipx" ]]; then
  echo "  🗑️  Cleaning pipx installation directory..."
  rm -rf "$HOME/.local/share/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.cache/pipx" ]]; then
  echo "  🗑️  Cleaning pipx cache directory..."
  rm -rf "$HOME/.cache/pipx" 2>/dev/null || true
fi

# Clean up pipx bin directory from PATH (if it exists)
if [[ -d "$HOME/.local/bin" ]]; then
  echo "  🗑️  Cleaning pipx binaries..."
  # Only remove pipx-installed binaries, keep other user binaries
  find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; 2>/dev/null || true
fi

echo "✅ Pipx cleanup completed"
