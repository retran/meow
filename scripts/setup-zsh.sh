#!/usr/bin/env bash

# scripts/setup-zsh.sh - Script to set up Zsh environment

set -euo pipefail

PRESET="$1"
DOTFILES_DIR="$2"
INDENT_LEVEL="${3:-0}"

source "${DOTFILES_DIR}/lib/core/ui.sh"

setup_ohmyzsh() {
  local indent="$1"

  step_header "$indent_level" "Configuring Zsh for preset: $PRESET"


  action_msg "$indent" "Checking for Oh My Zsh installation..."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success_tick_msg "$indent" "Oh My Zsh is already installed."
    action_msg "$indent" "Updating Oh My Zsh..."
    if zsh "$HOME/.oh-my-zsh/tools/upgrade.sh"; then
        success_tick_msg "$indent" "Oh My Zsh update completed."
        return 0
    else
        indented_error_msg "$indent" "Failed to update Oh My Zsh."
        return 1
    fi
  fi

  action_msg "$indent" "Installing Oh My Zsh..."
  if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    success_tick_msg "$indent" "Oh My Zsh installation completed."
    return 0
  else
    indented_error_msg "$indent" "Failed to install Oh My Zsh."
    return 1
  fi
}

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up Zsh environment for preset: $PRESET"

  if setup_ohmyzsh "$indent_level"; then
    success_tick_msg "$indent_level" "Zsh environment setup complete."
  else
    indented_warning "$indent_level" "Zsh environment setup encountered issues."
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
