#!/usr/bin/env bash

# Meowvim component cleanup script
# This script is executed when the meowvim component is being uninstalled

set -euo pipefail

echo "🧹 Running Meowvim cleanup..."

# Clean up Neovim cache and logs
if [[ -d "$HOME/.cache/nvim" ]]; then
    echo "  🗑️  Cleaning Neovim cache..."
    rm -rf "$HOME/.cache/nvim" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/state/nvim" ]]; then
    echo "  🗑️  Cleaning Neovim state files..."
    rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
fi

# Clean up Vim cache
if [[ -d "$HOME/.vim/tmp" ]]; then
    echo "  🗑️  Cleaning Vim temporary files..."
    rm -rf "$HOME/.vim/tmp" 2>/dev/null || true
fi

# Clean up swap files
echo "  🗑️  Cleaning Vim/Neovim swap files..."
find "$HOME" -name "*.swp" -delete 2>/dev/null || true
find "$HOME" -name "*.swo" -delete 2>/dev/null || true
find "$HOME" -name "*~" -delete 2>/dev/null || true

# Clean up backup files
find "$HOME" -name ".*.un~" -delete 2>/dev/null || true

# Clean up plugin manager cache (lazy.nvim, packer, etc.)
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
    echo "  🗑️  Cleaning Lazy.nvim cache..."
    rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/share/nvim/site/pack/packer" ]]; then
    echo "  🗑️  Cleaning Packer cache..."
    rm -rf "$HOME/.local/share/nvim/site/pack/packer" 2>/dev/null || true
fi

echo "✅ Meowvim cleanup completed"
