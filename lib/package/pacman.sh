#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_PACMAN_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PACMAN_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_pacman_packages() {
  cache_package_list "pacman" "pacman -Qq 2>/dev/null"
}

is_pacman_package_installed() {
  _cache_installed_pacman_packages
  grep -qE "^$1$" <<<"${_PACMAN_INSTALLED_PACKAGES}"
}

setup_pacman() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "pacman_setting_up")"
  fi

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v pacman >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "pacman_not_found_would_fail")"
    else
      dry_run_ui_info "$(get_static_message "pacman_would_sync_db")"
      dry_run_ui_info "  $(get_static_message "pacman_sync_command")"
      dry_run_ui_info "  $(get_static_message "pacman_would_refresh_info")"
    fi
    return 0
  fi

  command -v pacman >/dev/null 2>&1 || {
    ui_error "$(get_static_message "pacman_not_found")"
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "$(parse_spinner_messages "pacman_sync")" \
      sudo pacman -Sy
  else
    sudo pacman -Sy >/dev/null 2>&1 || {
      ui_error "$(get_static_message "pacman_failed_sync")"
      return 1
    }
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_action_success "$(get_static_message "pacman_setup_complete")"
  fi
}

install_pacman_packages() {
  install_packages_generic "$1" "pacman" "sudo pacman -S --noconfirm" "is_pacman_package_installed"
}

update_pacman_packages() {
  update_packages_generic "$1" "pacman" "sudo pacman -Syu --noconfirm" "is_pacman_package_installed"
}

uninstall_pacman_packages() {
  uninstall_packages_generic "$1" "pacman" "sudo pacman -R --noconfirm" "is_pacman_package_installed"
}

cleanup_pacman() {
  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "$(get_static_message "pacman_would_clean_cache")"
    dry_run_ui_info "  $(get_static_message "pacman_clean_command")"
    dry_run_ui_info "  $(get_static_message "pacman_would_remove_cached")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "pacman_cleaning")"
    ui_spinner "$(parse_spinner_messages "pacman_prune")" \
      sudo pacman -Sc --noconfirm
  else
    ui_spinner "$(parse_spinner_messages "pacman_cleanup")" \
      sudo pacman -Sc --noconfirm
  fi
}
