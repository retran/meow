#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_ZSH_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_ZSH_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_ohmyzsh() {
  ui_action_start "$(fmt "zsh_checking_ohmyzsh")"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ui_action_success "$(fmt "zsh_ohmyzsh_already_installed")"

    ui_spinner "$(fmt "zsh_updating_ohmyzsh")" \
      --success "$(fmt "zsh_ohmyzsh_update_completed")" \
      --fail "$(fmt "zsh_ohmyzsh_update_failed")" \
      sh -c 'ZSH="$HOME/.oh-my-zsh" zsh -i "$HOME/.oh-my-zsh/tools/upgrade.sh"'

    return $?
  fi

  ui_spinner "$(fmt "zsh_installing_ohmyzsh")" \
    --success "$(fmt "zsh_ohmyzsh_install_completed")" \
    --fail "$(fmt "zsh_ohmyzsh_install_failed")" \
    sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

  return $?
}

configure_zsh() {
  ui_step_header "$(fmt "zsh_setting_up_environment")"

  if setup_ohmyzsh; then
    ui_action_success "$(fmt "zsh_environment_setup_complete")"
    return 0
  else
    ui_warning "$(fmt "zsh_setup_issues")"
    return 1
  fi
}
