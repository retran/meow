#!/usr/bin/env bash

# lib/package/pacman.sh - Pacman package management (Arch Linux)

if [[ -n "${_LIB_PACKAGE_PACMAN_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PACMAN_SOURCED=1

source "${MEOW}/lib/package/common.sh"

PACMAN_PACKAGES_DIR="${MEOW}/packages/pacman"

_cache_installed_pacman_packages() {
  if [[ -z "${_PACMAN_INSTALLED_PACKAGES:-}" ]]; then
    action_msg 0 "Caching pacman package list..."
    _PACMAN_INSTALLED_PACKAGES="$(pacman -Qq 2>/dev/null)"
  fi
}

is_pacman_package_installed() {
  _cache_installed_pacman_packages
  grep -xq "$1" <<<"$_PACMAN_INSTALLED_PACKAGES"
}

setup_pacman() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up pacman"
  command -v pacman >/dev/null 2>&1 || {
    indented_error_msg "$indent" "pacman not found"
    return 1
  }
  ui_spinner "$((indent + 1))" "Syncing package database" \
    --success "pacman database synced" \
    --fail "Failed to sync pacman database" \
    sudo pacman -Sy
  success_tick_msg "$indent" "pacman ready"
}

install_pacman_packages() {
  install_packages_generic "$1" "$2" "pacman" "sudo pacman -S --noconfirm" "is_pacman_package_installed"
}

update_pacman_packages() {
  install_packages_generic "$1" "$2" "pacman" "sudo pacman -Syu --noconfirm" "is_pacman_package_installed"
}

cleanup_pacman() {
  local indent="${1:-0}"
  step_header "$indent" "Cleaning pacman cache"
  ui_spinner "$((indent + 1))" "Clearing pacman cache" \
    --success "pacman cache cleaned" \
    --fail "Failed to clean pacman cache" \
    sudo pacman -Scc --noconfirm
  success_tick_msg "$indent" "pacman cache cleaned"
}
