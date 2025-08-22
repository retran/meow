#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_ZSH_PLUGINS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_ZSH_PLUGINS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"

# Install Zsh plugins for non-macOS systems
install_zsh_plugins() {
  if [[ "$IS_DEBIAN_BASED" == "true" || "$IS_ALPINE" == "true" ]]; then
    ui_action_start "$(get_static_message "checking_zsh_plugins")"

    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ -d "$zsh_custom_dir" ]]; then
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-autosuggestions" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
          "${zsh_custom_dir}/plugins/zsh-autosuggestions" >/dev/null 2>&1
      fi
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
          "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
      fi
      ui_action_success "$(get_static_message "zsh_plugins_checked_installed")"
    else
      ui_warning "$(format_template_message "oh_my_zsh_dir_not_found" "$zsh_custom_dir")"
    fi
  fi
}
