#!/usr/bin/env bash

# Rust Development component cleanup script
# This script is executed when the rust-development component is being uninstalled

set -euo pipefail

echo "🧹 Running Rust Development cleanup..."

# Clear cargo cache
if command -v cargo >/dev/null 2>&1; then
  echo "  📦 Cleaning cargo cache..."
  cargo cache --autoclean 2>/dev/null || true

  echo "  🗑️  Cleaning cargo registry cache..."
  if [[ -d "$HOME/.cargo/registry" ]]; then
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
  fi

  echo "  🗑️  Cleaning cargo git cache..."
  if [[ -d "$HOME/.cargo/git" ]]; then
    rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
  fi
fi

# Clean up target directories in common development locations
echo "  🗑️  Cleaning Rust target directories..."
find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up Rustup temp files
if [[ -d "$HOME/.rustup/tmp" ]]; then
  echo "  🗑️  Cleaning rustup temporary files..."
  rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
fi

echo "✅ Rust Development cleanup completed"
