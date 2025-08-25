#!/usr/bin/env bash

if [ -n "${_LIB_SYSTEM_ZSH_PLUGINS_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_ZSH_PLUGINS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"

install_zsh_plugins() {
  if [ "$IS_DEBIAN_BASED" = "true" ] || [ "$IS_ALPINE" = "true" ]; then
    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_installed_count=0
    local plugins_skipped_count=0
    local plugins_failed_count=0
    local return_status=0

    ui_action_start "$(_f "Checking Zsh plugins in '%s'" "$zsh_custom_dir")"

    if [ -d "$zsh_custom_dir" ]; then
      if [ ! -d "${zsh_custom_dir}/plugins/zsh-autosuggestions" ]; then
        ui_action_start "$(_f "Cloning zsh-autosuggestions to '%s/plugins'" "$zsh_custom_dir")"
        if git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
          "${zsh_custom_dir}/plugins/zsh-autosuggestions" >/dev/null 2>&1; then
          ui_action_success "zsh-autosuggestions cloned successfully"
          plugins_installed_count=$((plugins_installed_count + 1))
        else
          ui_action_fail "$(_f "Failed to clone zsh-autosuggestions. Check internet connection or permissions.")"
          plugins_failed_count=$((plugins_failed_count + 1))
          return_status=1
        fi
      else
        ui_info "$(_f "zsh-autosuggestions already installed in '%s/plugins'." "$zsh_custom_dir")"
        plugins_skipped_count=$((plugins_skipped_count + 1))
      fi

      if [ ! -d "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" ]; then
        ui_action_start "$(_f "Cloning zsh-syntax-highlighting to '%s/plugins'" "$zsh_custom_dir")"
        if git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
          "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" >/dev/null 2>&1; then
          ui_action_success "zsh-syntax-highlighting cloned successfully"
          plugins_installed_count=$((plugins_installed_count + 1))
        else
          ui_action_fail "$(_f "Failed to clone zsh-syntax-highlighting. Check internet connection or permissions.")"
          plugins_failed_count=$((plugins_failed_count + 1))
          return_status=1
        fi
      else
        ui_info "$(_f "zsh-syntax-highlighting already installed in '%s/plugins'." "$zsh_custom_dir")"
        plugins_skipped_count=$((plugins_skipped_count + 1))
      fi

      if [ "$plugins_failed_count" -gt 0 ]; then
        ui_action_fail "$(_f "Zsh plugin check completed with %d failures, %d installed, %d skipped." "$plugins_failed_count" "$plugins_installed_count" "$plugins_skipped_count")"
      elif [ "$plugins_installed_count" -gt 0 ]; then
        ui_action_success "$(_f "Zsh plugin check completed: %d installed, %d skipped." "$plugins_installed_count" "$plugins_skipped_count")"
      else
        ui_action_success "All required Zsh plugins are already installed."
      fi

    else
      ui_warning "$(_f "Oh My Zsh custom directory not found at '%s'. Skipping Zsh plugin installation." "$zsh_custom_dir")"
      return_status=1
    fi
    return "$return_status"
  else
    ui_info "Zsh plugin installation is only for Debian-based or Alpine systems. Skipping."
    return 0
  fi
}
