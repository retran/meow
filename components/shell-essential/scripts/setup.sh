#!/usr/bin/env bash

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/system/tmux.sh"
source "${MEOW}/lib/system/zsh.sh"
source "${MEOW}/lib/system/zsh_plugins.sh"
source "${MEOW}/lib/core/ui.sh"

install_zsh_plugins

if command -v tmux >/dev/null 2>&1; then
  ui_info "Configuring tmux"
  configure_tmux || true
fi

if command -v zsh >/dev/null 2>&1; then
  ui_info "Configuring zsh"
  configure_zsh || true
fi
