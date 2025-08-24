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
    ui_step_header "Setting up pacman"
  fi

  if is_dry_run; then
    if ! command -v pacman >/dev/null 2>&1; then
      dry_run_ui_info "pacman not found - would fail setup"
    else
      dry_run_ui_info "Would sync pacman package database"
      dry_run_ui_info "  Command: sudo pacman -Sy"
      dry_run_ui_info "  Would refresh available package information"
    fi
    return 0
  fi

  command -v pacman >/dev/null 2>&1 || {
    ui_error "pacman not found"
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "$(parse_spinner_messages "pacman_sync")" \
      sudo pacman -Sy
  else
    sudo pacman -Sy >/dev/null 2>&1 || {
      ui_error "Failed to sync pacman database"
      return 1
    }
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_action_success "pacman ready"
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
  if is_dry_run; then
    dry_run_ui_info "Would clean pacman package cache"
    dry_run_ui_info "  Command: sudo pacman -Sc --noconfirm"
    dry_run_ui_info "  Would remove cached packages not currently installed"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning pacman"
    ui_spinner "$(parse_spinner_messages "pacman_prune")" \
      sudo pacman -Sc --noconfirm
  else
    ui_spinner "$(parse_spinner_messages "pacman_cleanup")" \
      sudo pacman -Sc --noconfirm
  fi
}
