#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_TMUX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_TMUX_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_tmux_plugin_manager() {
  if ! command -v tmux >/dev/null 2>&1; then
    warning "tmux is not installed, skipping Plugin Manager setup"
    return 0
  fi

  step_header "Setting up tmux Plugin Manager"

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    success_tick_msg "tmux Plugin Manager is already installed."
    action_msg "Updating tmux Plugin Manager..."
    if git -C "$HOME/.tmux/plugins/tpm" pull; then
      success_tick_msg "tmux Plugin Manager update completed"
      return 0
    else
      error_msg "Failed to update tmux Plugin Manager."
      return 1
    fi
  fi

  mkdir -p "$HOME/.tmux/plugins"

  if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
    success_tick_msg "tmux Plugin Manager installation completed"
    return 0
  else
    error_msg "Failed to install tmux Plugin Manager."
    return 1
  fi
}

configure_tmux() {
  step_header "Setting up tmux environment"

  if setup_tmux_plugin_manager; then
    success_tick_msg "tmux environment setup complete."
    return 0
  else
    warning "tmux environment setup encountered issues"
    return 1
  fi
}
