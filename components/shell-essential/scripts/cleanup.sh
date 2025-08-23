#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "shell_essential_cleanup_running")"

if [[ -d "$HOME/.zsh_cache" ]]; then
  ui_info "$(get_static_message "shell_essential_cleaning_zsh_cache")"
  rm -rf "$HOME/.zsh_cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.oh-my-zsh/cache" ]]; then
  ui_info "$(get_static_message "shell_essential_cleaning_omz_cache")"
  rm -rf "$HOME/.oh-my-zsh/cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.tmux" ]]; then
  ui_info "$(get_static_message "shell_essential_cleaning_tmux_cache")"
  rm -rf "$HOME/.tmux/logs" 2>/dev/null || true
  rm -rf "$HOME/.tmux/resurrect" 2>/dev/null || true
fi

ui_info "$(get_static_message "shell_essential_cleaning_history_backups")"
rm -f "$HOME/.zsh_history.old" 2>/dev/null || true
rm -f "$HOME/.bash_history.old" 2>/dev/null || true

if [[ -d "$HOME/.zcompdump" ]]; then
  ui_info "$(get_static_message "shell_essential_cleaning_completion_cache")"
  rm -f "$HOME/.zcompdump*" 2>/dev/null || true
fi

if [[ -d "$HOME/.fzf" ]]; then
  ui_info "$(get_static_message "shell_essential_cleaning_fzf_cache")"
  rm -rf "$HOME/.fzf/.git" 2>/dev/null || true
fi

ui_success "$(get_static_message "shell_essential_cleanup_completed")"
