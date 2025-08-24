#!/usr/bin/env bash

# Sourcing guard: prevents multiple executions if sourced, and ensures it's run only once.
if [[ -n "${_LIB_SYSTEM_TMUX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_TMUX_SOURCED=1

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# The exit status of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if all commands exit successfully.

source "${MEOW}/lib/core/ui.sh"

# Sets up the tmux Plugin Manager (tpm).
# Checks if tmux is installed, then either clones tpm or updates it.
setup_tmux_plugin_manager() {
  if ! command -v tmux >/dev/null 2>&1; then
    ui_warning "tmux is not installed. Skipping Plugin Manager setup."
    return 0
  fi

  ui_step_header "Setting up tmux Plugin Manager"

  # If tpm is already installed, update it.
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    ui_action_success "tmux Plugin Manager is already installed."

    ui_spinner "Updating tmux Plugin Manager..." \
      --success "tmux Plugin Manager updated." \
      --fail "Failed to update tmux Plugin Manager." \
      git -C "$HOME/.tmux/plugins/tpm" pull

    return $?
  fi

  # Create the plugins directory if it doesn't exist.
  mkdir -p "$HOME/.tmux/plugins"

  # Install tpm by cloning the repository.
  ui_spinner "Installing tmux Plugin Manager..." \
    --success "tmux Plugin Manager installed." \
    --fail "Failed to install tmux Plugin Manager." \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
}

# Configures the overall tmux environment.
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
