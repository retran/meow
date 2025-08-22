#!/usr/bin/env bash

# Meowvim component cleanup script
# This script is executed when the meowvim component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "meowvim_cleanup_running")"

# Clean Neovim cache and data
if [[ -d "$HOME/.local/share/nvim" ]]; then
  echo "$(get_static_message "meowvim_cleaning_neovim_cache")"
  rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
fi

# Clean Neovim state files
if [[ -d "$HOME/.local/state/nvim" ]]; then
  echo "$(get_static_message "meowvim_cleaning_neovim_state")"
  rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
fi

# Clean Vim temporary files
if [[ -d "$HOME/.vim/tmp" ]]; then
  echo "$(get_static_message "meowvim_cleaning_vim_temp")"
  rm -rf "$HOME/.vim/tmp" 2>/dev/null || true
fi

echo "$(get_static_message "meowvim_cleaning_swap_files")"

# Clean up swap, backup, and undo files in common locations
find "$HOME" -name ".*.swp" -delete 2>/dev/null || true
find "$HOME" -name ".*.swo" -delete 2>/dev/null || true
find "$HOME" -name ".*.un~" -delete 2>/dev/null || true
find "$HOME" -name "*~" -maxdepth 1 -delete 2>/dev/null || true

# Clean Lazy.nvim cache if it exists
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  echo "$(get_static_message "meowvim_cleaning_lazy_cache")"
  rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true
fi

# Clean Packer cache if it exists
if [[ -d "$HOME/.local/share/nvim/site/pack/packer" ]]; then
  echo "$(get_static_message "meowvim_cleaning_packer_cache")"
  rm -rf "$HOME/.local/share/nvim/site/pack/packer" 2>/dev/null || true
fi

echo "$(get_static_message "meowvim_cleanup_completed")"
