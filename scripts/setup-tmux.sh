#!/usr/bin/env bash

# scripts/setup-tmux.sh - Script to set up tmux environment

set -euo pipefail

PRESET="$1"
DOTFILES_DIR="$2"
INDENT_LEVEL="${3:-0}"

source "${DOTFILES_DIR}/lib/core/ui.sh"

setup_tmux_plugin_manager() {
  local indent="$1"

  step_header "$indent_level" "Configuring tmux for preset: $PRESET"

  if ! command -v tmux &>/dev/null; then
    indented_warning "$indent" "tmux is not installed, skipping Plugin Manager setup"
    return 0
  fi

  step_header "$indent" "Setting up tmux Plugin Manager"
  action_msg "$indent" "Checking for tmux Plugin Manager installation..."

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    success_tick_msg "$indent" "tmux Plugin Manager is already installed."
    action_msg "$indent" "Updating tmux Plugin Manager..."
    if git -C "$HOME/.tmux/plugins/tpm" pull; then
        success_tick_msg "$indent" "tmux Plugin Manager update completed."
        return 0
    else
        indented_error_msg "$indent" "Failed to update tmux Plugin Manager."
        return 1
    fi
  fi

  action_msg "$indent" "Creating tmux plugins directory..."
  mkdir -p "$HOME/.tmux/plugins"

  action_msg "$indent" "Installing tmux Plugin Manager..."
  if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
    success_tick_msg "$indent" "tmux Plugin Manager installation completed."
    return 0
  else
    indented_error_msg "$indent" "Failed to install tmux Plugin Manager."
    return 1
  fi
}

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up tmux environment for preset: $PRESET"

  if setup_tmux_plugin_manager "$indent_level"; then
    success_tick_msg "$indent_level" "tmux environment setup complete."
  else
    indented_warning "$indent_level" "tmux environment setup encountered issues."
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
