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

    ui_spinner "Updating tmux Plugin Manager" \
      --success "tmux Plugin Manager update completed" \
      --fail "Failed to update tmux Plugin Manager" \
      git -C "$HOME/.tmux/plugins/tpm" pull

    return $?
  fi

  mkdir -p "$HOME/.tmux/plugins"

  ui_spinner "Installing tmux Plugin Manager" \
    --success "tmux Plugin Manager installation completed" \
    --fail "Failed to install tmux Plugin Manager" \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
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
