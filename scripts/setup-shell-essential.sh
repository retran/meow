#!/usr/bin/env bash

# scripts/setup-shell-essential.sh - Script to set up essential shell environment

set -euo pipefail

PRESET="$1"
DOTFILES_DIR="$2"
INDENT_LEVEL="${3:-0}"

source "${DOTFILES_DIR}/lib/core/ui.sh"

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up essential shell environment for preset: $PRESET"

  # Set up tmux
  if command -v tmux >/dev/null 2>&1; then
    info_msg "$indent_level" "Setting up tmux..."
    "${DOTFILES_DIR}/scripts/setup-tmux.sh" "$PRESET" "$DOTFILES_DIR" "$((indent_level + 1))" || true
  fi

  # Set up zsh
  if command -v zsh >/dev/null 2>&1; then
    info_msg "$indent_level" "Setting up zsh..."
    "${DOTFILES_DIR}/scripts/setup-zsh.sh" "$PRESET" "$DOTFILES_DIR" "$((indent_level + 1))" || true
  fi

  success_tick_msg "$indent_level" "Essential shell environment setup complete"
}

main "$@"