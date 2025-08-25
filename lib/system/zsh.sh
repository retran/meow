#!/usr/bin/env bash

if [ -n "${_LIB_SYSTEM_ZSH_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_ZSH_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_ohmyzsh() {
  ui_action_start "Checking for Oh My Zsh installation..."

  local ohmyzsh_path="$HOME/.oh-my-zsh"

  if [ -d "$ohmyzsh_path" ]; then
    ui_action_success "Oh My Zsh is already installed."

    if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
      ui_action_start "Skipping Oh My Zsh update (dry-run mode)"
      return 0
    fi

    ui_spinner "Updating Oh My Zsh..." \
      --success "Oh My Zsh updated successfully." \
      --fail "Failed to update Oh My Zsh." \
      sh -c "ZSH=\"\$1\" zsh -c \"source \\\"\$ZSH/oh-my-zsh.sh\\\" && omz update\"" _ "$ohmyzsh_path"

    return $?
  fi

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_action_start "Skipping Oh My Zsh installation (dry-run mode)"
    return 0
  fi

  ui_spinner "Installing Oh My Zsh..." \
    --success "Oh My Zsh installed successfully." \
    --fail "Failed to install Oh My Zsh." \
    sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh'

  return $?
}

configure_zsh() {
  ui_step_header "Setting up Zsh environment"

  if setup_ohmyzsh; then
    ui_action_success "Zsh environment setup complete."
    return 0
  else
    ui_warning "Zsh environment setup encountered issues."
    return 1
  fi
}
