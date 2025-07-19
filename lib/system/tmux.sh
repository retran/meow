#!/usr/bin/env bash

# lib/system/tmux.sh - tmux setup functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_TMUX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_TMUX_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_tmux_plugin_manager() {
  local indent_level="${1:-1}"

  if ! command -v tmux >/dev/null 2>&1; then
    indented_warning "$indent_level" "tmux is not installed, skipping Plugin Manager setup"
    return 0
  fi

  step_header "$indent_level" "Setting up tmux Plugin Manager"
  action_msg "$indent_level" "Checking for tmux Plugin Manager installation..."

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    success_tick_msg "$indent_level" "tmux Plugin Manager is already installed."
    action_msg "$indent_level" "Updating tmux Plugin Manager..."
    if git -C "$HOME/.tmux/plugins/tpm" pull; then
        success_tick_msg "$indent_level" "tmux Plugin Manager update completed."
        return 0
    else
        indented_error_msg "$indent_level" "Failed to update tmux Plugin Manager."
        return 1
    fi
  fi

  action_msg "$indent_level" "Creating tmux plugins directory..."
  mkdir -p "$HOME/.tmux/plugins"

  action_msg "$indent_level" "Installing tmux Plugin Manager..."
  if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
    success_tick_msg "$indent_level" "tmux Plugin Manager installation completed."
    return 0
  else
    indented_error_msg "$indent_level" "Failed to install tmux Plugin Manager."
    return 1
  fi
}

configure_tmux() {
  local indent_level="${1:-0}"

  step_header "$indent_level" "Setting up tmux environment"

  if setup_tmux_plugin_manager "$((indent_level + 1))"; then
    success_tick_msg "$indent_level" "tmux environment setup complete."
    return 0
  else
    indented_warning "$indent_level" "tmux environment setup encountered issues."
    return 1
  fi
}