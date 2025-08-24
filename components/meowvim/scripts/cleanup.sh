#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "meowvim_cleanup_running")"

if [[ -d "$HOME/.local/share/nvim" ]]; then
  ui_info "$(fmt "meowvim_cleaning_neovim_cache")"
  rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/state/nvim" ]]; then
  ui_info "$(fmt "meowvim_cleaning_neovim_state")"
  rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
fi

if [[ -d "$HOME/.vim/tmp" ]]; then
  ui_info "$(fmt "meowvim_cleaning_vim_temp")"
  rm -rf "$HOME/.vim/tmp" 2>/dev/null || true
fi

ui_info "$(fmt "meowvim_cleaning_swap_files")"

find "$HOME" -name ".*.swp" -delete 2>/dev/null || true
find "$HOME" -name ".*.swo" -delete 2>/dev/null || true
find "$HOME" -name ".*.un~" -delete 2>/dev/null || true
find "$HOME" -name "*~" -maxdepth 1 -delete 2>/dev/null || true

if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ui_info "$(fmt "meowvim_cleaning_lazy_cache")"
  rm -rf "$HOME/.local/share/nvim/lazy" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/share/nvim/site/pack/packer" ]]; then
  ui_info "$(fmt "meowvim_cleaning_packer_cache")"
  rm -rf "$HOME/.local/share/nvim/site/pack/packer" 2>/dev/null || true
fi

ui_success "$(fmt "meowvim_cleanup_completed")"
