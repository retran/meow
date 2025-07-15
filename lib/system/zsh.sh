#!/usr/bin/env bash

# lib/system/zsh.sh - zsh setup functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_ZSH_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_ZSH_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

setup_ohmyzsh() {
  local indent_level="${1:-1}"

  action_msg "$indent_level" "Checking for Oh My Zsh installation..."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success_tick_msg "$indent_level" "Oh My Zsh is already installed."
    action_msg "$indent_level" "Updating Oh My Zsh..."
    if zsh "$HOME/.oh-my-zsh/tools/upgrade.sh"; then
        success_tick_msg "$indent_level" "Oh My Zsh update completed."
        return 0
    else
        indented_error_msg "$indent_level" "Failed to update Oh My Zsh."
        return 1
    fi
  fi

  action_msg "$indent_level" "Installing Oh My Zsh..."
  if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    success_tick_msg "$indent_level" "Oh My Zsh installation completed."
    return 0
  else
    indented_error_msg "$indent_level" "Failed to install Oh My Zsh."
    return 1
  fi
}

configure_zsh() {
  local indent_level="${1:-0}"

  step_header "$indent_level" "Setting up Zsh environment"

  if setup_ohmyzsh "$((indent_level + 1))"; then
    success_tick_msg "$indent_level" "Zsh environment setup complete."
    return 0
  else
    indented_warning "$indent_level" "Zsh environment setup encountered issues."
    return 1
  fi
}