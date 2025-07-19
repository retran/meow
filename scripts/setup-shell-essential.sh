#!/usr/bin/env bash

# scripts/setup-shell-essential.sh - Script to set up essential shell environment

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/system/rust.sh"
source "${MEOW}/lib/system/tmux.sh"
source "${MEOW}/lib/system/zsh.sh"

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up essential shell environment for preset: $PRESET"

  setup_rustup "$((indent_level + 1))" || true

  if command -v tmux >/dev/null 2>&1; then
    info "$indent_level" "Setting up tmux..."
    configure_tmux "$((indent_level + 1))" || true
  fi

  if command -v zsh >/dev/null 2>&1; then
    info "$indent_level" "Setting up zsh..."
    configure_zsh "$((indent_level + 1))" || true
  fi

  success_tick_msg "$indent_level" "Essential shell environment setup complete"
}

main "$@"
