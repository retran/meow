#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_TMUX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_TMUX_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_tmux_plugin_manager() {
  if ! command -v tmux >/dev/null 2>&1; then
    ui_warning "$(fmt "tmux_not_installed_skip_plugin")"
    return 0
  fi

  ui_step_header "$(fmt "tmux_setting_up_plugin_manager")"

  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    ui_action_success "$(fmt "tmux_plugin_manager_already_installed")"

    ui_spinner "$(fmt "tmux_updating_plugin_manager")" \
      --success "$(fmt "tmux_plugin_manager_update_completed")" \
      --fail "$(fmt "tmux_plugin_manager_update_failed")" \
      git -C "$HOME/.tmux/plugins/tpm" pull

    return $?
  fi

  mkdir -p "$HOME/.tmux/plugins"

  ui_spinner "$(fmt "tmux_installing_plugin_manager")" \
    --success "$(fmt "tmux_plugin_manager_install_completed")" \
    --fail "$(fmt "tmux_plugin_manager_install_failed")" \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
}

configure_tmux() {
  ui_step_header "$(fmt "tmux_setting_up_environment")"

  if setup_tmux_plugin_manager; then
    ui_action_success "$(fmt "tmux_environment_setup_complete")"
    return 0
  else
    ui_warning "$(fmt "tmux_setup_issues")"
    return 1
  fi
}
