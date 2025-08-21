#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_PACMAN_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PACMAN_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_pacman_packages() {
  cache_package_list "pacman" "pacman -Qq 2>/dev/null"
}

is_pacman_package_installed() {
  _cache_installed_pacman_packages
  grep -qE "^$1$" <<<"${_PACMAN_INSTALLED_PACKAGES}"
}

setup_pacman() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Setting up pacman"
  fi

  command -v pacman >/dev/null 2>&1 || {
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "Syncing package database" \
      --success "pacman database synced" \
      --fail "Failed to sync pacman database" \
      sudo pacman -Sy
  else
    sudo pacman -Sy >/dev/null 2>&1
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    success_tick_msg "pacman ready"
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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cleaning pacman"
    ui_spinner "Pruning cache" \
      --success "pacman cleanup completed" \
      --fail "pacman cleanup failed" \
      sudo pacman -Sc --noconfirm
  else
    ui_spinner "Cleaning pacman" \
      --success "pacman cleanup completed" \
      --fail "pacman cleanup failed" \
      sudo pacman -Sc --noconfirm
  fi
}
