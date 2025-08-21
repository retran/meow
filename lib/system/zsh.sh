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

    ui_spinner "Updating Oh My Zsh" \
      --success "Oh My Zsh update completed" \
      --fail "Failed to update Oh My Zsh" \
      sh -c 'ZSH="$HOME/.oh-my-zsh" zsh -i "$HOME/.oh-my-zsh/tools/upgrade.sh"'

    return $?
  fi

  ui_spinner "Installing Oh My Zsh" \
    --success "Oh My Zsh installation completed" \
    --fail "Failed to install Oh My Zsh" \
    sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

  return $?
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
