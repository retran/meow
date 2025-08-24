#!/usr/bin/env bash

# Source the UI library, expected to provide ui_info and ui_success functions.
# The path to 'ui.sh' is assumed to be correctly set via the MEOW environment variable.
source "${MEOW}/lib/core/ui.sh"

ui_info "Starting essential shell cleanup..."

# Clean Zsh cache directory
if [[ -d "$HOME/.zsh_cache" ]]; then
  ui_info "Cleaning Zsh cache directory: '$HOME/.zsh_cache'"
  rm -rf "$HOME/.zsh_cache" 2>/dev/null || true
fi

# Clean Oh My Zsh cache directory
if [[ -d "$HOME/.oh-my-zsh/cache" ]]; then
  ui_info "Cleaning Oh My Zsh cache directory: '$HOME/.oh-my-zsh/cache'"
  rm -rf "$HOME/.oh-my-zsh/cache" 2>/dev/null || true
fi

# Clean Tmux logs and resurrect cache
if [[ -d "$HOME/.tmux" ]]; then
  ui_info "Cleaning Tmux session logs and resurrect cache..."
  rm -rf "$HOME/.tmux/logs" 2>/dev/null || true
  rm -rf "$HOME/.tmux/resurrect" 2>/dev/null || true
fi

# Clean old shell history backup files
ui_info "Cleaning old shell history backup files..."
rm -f "$HOME/.zsh_history.old" 2>/dev/null || true
rm -f "$HOME/.bash_history.old" 2>/dev/null || true

# Clean Zsh completion cache files
# Note: The original condition checks for '$HOME/.zcompdump' as a directory.
# The 'rm' command targets all files matching '$HOME/.zcompdump*'.
# This behavior is preserved as per requirements.
if [[ -d "$HOME/.zcompdump" ]]; then
  ui_info "Cleaning Zsh completion cache files..."
  rm -f "$HOME/.zcompdump*" 2>/dev/null || true
fi

# Clean fzf internal Git repository cache
if [[ -d "$HOME/.fzf" ]]; then
  ui_info "Cleaning fzf Git repository cache..."
  rm -rf "$HOME/.fzf/.git" 2>/dev/null || true
fi

ui_success "Essential shell cleanup completed successfully."
