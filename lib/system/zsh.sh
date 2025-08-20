#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_ZSH_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_ZSH_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_ohmyzsh() {
  action_msg "Checking for Oh My Zsh installation..."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success_tick_msg "Oh My Zsh is already installed."
    action_msg "Updating Oh My Zsh..."

    if ZSH="$HOME/.oh-my-zsh" zsh -i "$HOME/.oh-my-zsh/tools/upgrade.sh" &>/dev/null; then
      success_tick_msg "Oh My Zsh update completed"
      return 0
    else
      error_msg "Failed to update Oh My Zsh."
      return 1
    fi
  fi

  action_msg "Installing Oh My Zsh..."

  if RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &>/dev/null; then
    success_tick_msg "Oh My Zsh installation completed"
    return 0
  else
    error_msg "Failed to install Oh My Zsh."
    return 1
  fi
}

configure_zsh() {
  step_header "Setting up Zsh environment"

  if setup_ohmyzsh; then
    success_tick_msg "Zsh environment setup complete."
    return 0
  else
    warning "Zsh environment setup encountered issues"
    return 1
  fi
}
