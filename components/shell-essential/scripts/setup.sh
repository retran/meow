#!/usr/bin/env bash

# COMPONENT_NAME is passed as the first argument, its usage might be in sourced files.
COMPONENT_NAME="$1"
# MEOW is passed as the second argument, used for sourcing library paths.
MEOW="$2"

# Source necessary library files
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/system/tmux.sh"
source "${MEOW}/lib/system/zsh.sh"
source "${MEOW}/lib/system/zsh_plugins.sh"
source "${MEOW}/lib/core/ui.sh"

# Install Zsh plugins
install_zsh_plugins

# Conditionally configure tmux if it is installed
if command -v tmux >/dev/null 2>&1; then
  ui_info "Configuring tmux"
  # Continue even if tmux configuration fails
  configure_tmux || true
fi

# Conditionally configure zsh if it is installed
if command -v zsh >/dev/null 2>&1; then
  ui_info "Configuring zsh"
  # Continue even if zsh configuration fails
  configure_zsh || true
fi
