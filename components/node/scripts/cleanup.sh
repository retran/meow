#!/usr/bin/env bash

# Node component cleanup script
# This script is executed when the node component is being uninstalled

set -euo pipefail

echo "🧹 Running Node cleanup..."

# Clear npm cache
if command -v npm >/dev/null 2>&1; then
    echo "  📦 Cleaning npm cache..."
    npm cache clean --force 2>/dev/null || true
fi

# Clear yarn cache if available
if command -v yarn >/dev/null 2>&1; then
    echo "  📦 Cleaning yarn cache..."
    yarn cache clean 2>/dev/null || true
fi

# Clear pnpm cache if available
if command -v pnpm >/dev/null 2>&1; then
    echo "  📦 Cleaning pnpm cache..."
    pnpm store prune 2>/dev/null || true
fi

# Remove global npm packages cache
if [[ -d "$HOME/.npm" ]]; then
    echo "  🗑️  Cleaning npm global cache..."
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
    rm -rf "$HOME/.npm/_logs" 2>/dev/null || true
fi

# Clean up node-gyp cache
if [[ -d "$HOME/.node-gyp" ]]; then
    echo "  🗑️  Cleaning node-gyp cache..."
    rm -rf "$HOME/.node-gyp" 2>/dev/null || true
fi

echo "✅ Node cleanup completed"
