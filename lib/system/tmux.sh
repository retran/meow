#!/usr/bin/env bash

# Sourcing guard: prevents multiple executions if sourced, and ensures it's run only once.
if [[ -n "${_LIB_SYSTEM_TMUX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_TMUX_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_tmux_plugin_manager() {
  if ! command -v tmux >/dev/null 2>&1; then
    ui_warning "tmux is not installed. Skipping Plugin Manager setup."
    return 0
  fi

  ui_step_header "Setting up tmux Plugin Manager"

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    ui_action_success "tmux Plugin Manager is already installed."

    ui_spinner "Updating tmux Plugin Manager..." \
      --success "tmux Plugin Manager updated." \
      --fail "Failed to update tmux Plugin Manager." \
      git -C "$HOME/.tmux/plugins/tpm" pull

    return $?
  fi

  mkdir -p "$HOME/.tmux/plugins"

  ui_spinner "Installing tmux Plugin Manager..." \
    --success "tmux Plugin Manager installed." \
    --fail "Failed to install tmux Plugin Manager." \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
}

configure_tmux() {
  ui_step_header "Setting up tmux environment"

  if setup_tmux_plugin_manager; then
    ui_action_success "tmux environment setup complete."
    return 0
  else
    ui_warning "tmux environment setup encountered issues."
    return 1
  fi
}
