#!/usr/bin/env bash

# JavaScript Development component cleanup script
# This script is executed when the js-development component is being uninstalled

set -euo pipefail

echo "🧹 Running JavaScript Development cleanup..."

# Clear npm cache
if command -v npm >/dev/null 2>&1; then
  echo "  📦 Cleaning npm cache..."
  npm cache clean --force 2>/dev/null || true
fi

# Remove TypeScript compiler cache
if [[ -d "$HOME/.tscache" ]]; then
  echo "  🗑️  Removing TypeScript cache..."
  rm -rf "$HOME/.tscache" || true
fi

# Clean up node_modules global symlinks (if any were created)
if [[ -d "$HOME/.npm-global" ]]; then
  echo "  🗑️  Cleaning up global npm packages cache..."
  rm -rf "$HOME/.npm-global/lib/node_modules/.cache" 2>/dev/null || true
fi

# Clear eslint cache
if [[ -d "$HOME/.eslintcache" ]]; then
  echo "  🗑️  Removing ESLint cache..."
  rm -rf "$HOME/.eslintcache" || true
fi

echo "✅ JavaScript Development cleanup completed"
