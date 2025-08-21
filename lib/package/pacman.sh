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
  step_header "Setting up pacman"
  command -v pacman >/dev/null 2>&1 || {
    error_msg "pacman not found"
    return 1
  }
  ui_spinner "Syncing package database" \
    --success "pacman database synced" \
    --fail "Failed to sync pacman database" \
    sudo pacman -Sy
  success_tick_msg "pacman ready"
}

install_pacman_packages() {
  install_packages_generic "$1" "pacman" "sudo pacman -S --noconfirm" "is_pacman_package_installed"
}

update_pacman_packages() {
  update_packages_generic "$1" "pacman" "sudo pacman -Syu --noconfirm" "is_pacman_package_installed"
}

cleanup_pacman() {
  step_header "Cleaning pacman cache"
  ui_spinner "Cleaning pacman cache" \
    --success "pacman cache cleaned" \
    --fail "pacman cache cleanup failed" \
    sudo pacman -Sc --noconfirm
}
