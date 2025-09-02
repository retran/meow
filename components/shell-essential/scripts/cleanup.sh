#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "Starting essential shell cleanup..."

if [ -d "$HOME/.zsh_cache" ]; then
  ui_info "Cleaning Zsh cache directory: '$HOME/.zsh_cache'"
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.zsh_cache'"
  else
    rm -rf "$HOME/.zsh_cache" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.oh-my-zsh/cache" ]; then
  ui_info "Cleaning Oh My Zsh cache directory: '$HOME/.oh-my-zsh/cache'"
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.oh-my-zsh/cache'"
  else
    rm -rf "$HOME/.oh-my-zsh/cache" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.tmux" ]; then
  ui_info "Cleaning Tmux session logs and resurrect cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.tmux/logs'"
    ui_warn "DRY-RUN: Would remove '$HOME/.tmux/resurrect'"
  else
    rm -rf "$HOME/.tmux/logs" 2>/dev/null || true
    rm -rf "$HOME/.tmux/resurrect" 2>/dev/null || true
  fi
fi

ui_info "Cleaning old shell history backup files..."
if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
  ui_warn "DRY-RUN: Would remove '$HOME/.zsh_history.old'"
  ui_warn "DRY-RUN: Would remove '$HOME/.bash_history.old'"
else
  rm -f "$HOME/.zsh_history.old" 2>/dev/null || true
  rm -f "$HOME/.bash_history.old" 2>/dev/null || true
fi

if [ -d "$HOME/.zcompdump" ]; then
  ui_info "Cleaning Zsh completion cache files..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.zcompdump*'"
  else
    rm -f "$HOME/.zcompdump*" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.fzf" ]; then
  ui_info "Cleaning fzf Git repository cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.fzf/.git'"
  else
    rm -rf "$HOME/.fzf/.git" 2>/dev/null || true
  fi
fi

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "Verbose mode enabled"
fi

ui_success "Essential shell cleanup completed successfully."
