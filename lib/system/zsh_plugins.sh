#!/usr/bin/env bash

# Set strict mode for script execution:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: The return value of a pipeline is the status of the last command
#              to exit with a non-zero status, or zero if all commands exit successfully.

# Prevent re-sourcing of this script.
# This check ensures that the script's content is processed only once
# if it's sourced multiple times, and allows it to run as a standalone script.
if [[ -n "${_LIB_SYSTEM_ZSH_PLUGINS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_ZSH_PLUGINS_SOURCED=1

# Source necessary libraries for UI functions and platform detection.
# ui.sh provides functions like ui_action_start, ui_action_success, ui_warning, ui_action_info, and _f for formatted messages.
source "${MEOW}/lib/core/ui.sh"
# platform.sh provides platform detection variables like IS_DEBIAN_BASED and IS_ALPINE.
source "${MEOW}/lib/core/platform.sh"

# install_zsh_plugins installs Zsh plugins for non-macOS systems.
# It checks for 'zsh-autosuggestions' and 'zsh-syntax-highlighting'
# and clones them if they are not already present in the ZSH_CUSTOM directory.
install_zsh_plugins() {
  # Only proceed if the system is Debian-based or Alpine.
  if [[ "$IS_DEBIAN_BASED" == "true" || "$IS_ALPINE" == "true" ]]; then
    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugins_installed_count=0
    local plugins_skipped_count=0
    local plugins_failed_count=0
    local return_status=0 # Default to success

    ui_action_start "$(_f "Checking Zsh plugins in '%s'" "$zsh_custom_dir")"

    if [[ -d "$zsh_custom_dir" ]]; then
      # Install zsh-autosuggestions if not already present.
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-autosuggestions" ]]; then
        ui_action_start "$(_f "Cloning zsh-autosuggestions to '%s/plugins'" "$zsh_custom_dir")"
        if git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
          "${zsh_custom_dir}/plugins/zsh-autosuggestions" >/dev/null 2>&1; then
          ui_action_success "zsh-autosuggestions cloned successfully"
          plugins_installed_count=$((plugins_installed_count + 1))
        else
          ui_action_fail "$(_f "Failed to clone zsh-autosuggestions. Check internet connection or permissions.")"
          plugins_failed_count=$((plugins_failed_count + 1))
          return_status=1 # Mark failure
        fi
      else
        ui_action_info "$(_f "zsh-autosuggestions already installed in '%s/plugins'." "$zsh_custom_dir")"
        plugins_skipped_count=$((plugins_skipped_count + 1))
      fi

      # Install zsh-syntax-highlighting if not already present.
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" ]]; then
        ui_action_start "$(_f "Cloning zsh-syntax-highlighting to '%s/plugins'" "$zsh_custom_dir")"
        if git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
          "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" >/dev/null 2>&1; then
          ui_action_success "zsh-syntax-highlighting cloned successfully"
          plugins_installed_count=$((plugins_installed_count + 1))
        else
          ui_action_fail "$(_f "Failed to clone zsh-syntax-highlighting. Check internet connection or permissions.")"
          plugins_failed_count=$((plugins_failed_count + 1))
          return_status=1 # Mark failure
        fi
      else
        ui_action_info "$(_f "zsh-syntax-highlighting already installed in '%s/plugins'." "$zsh_custom_dir")"
        plugins_skipped_count=$((plugins_skipped_count + 1))
      fi

      # Provide a final summary message based on the installation results.
      if [[ "$plugins_failed_count" -gt 0 ]]; then
        ui_action_fail "$(_f "Zsh plugin check completed with %d failures, %d installed, %d skipped." "$plugins_failed_count" "$plugins_installed_count" "$plugins_skipped_count")"
      elif [[ "$plugins_installed_count" -gt 0 ]]; then
        ui_action_success "$(_f "Zsh plugin check completed: %d installed, %d skipped." "$plugins_installed_count" "$plugins_skipped_count")"
      else
        ui_action_success "All required Zsh plugins are already installed."
      fi

    else
      ui_warning "$(_f "Oh My Zsh custom directory not found at '%s'. Skipping Zsh plugin installation." "$zsh_custom_dir")"
      return_status=1 # Indicate that Zsh custom dir was not found, which is a problem for installation.
    fi
    return "$return_status"
  else
    ui_action_info "Zsh plugin installation is only for Debian-based or Alpine systems. Skipping."
    return 0
  fi
}
