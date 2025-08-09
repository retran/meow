#!/usr/bin/env bash

# lib/package/mas.sh - Mac App Store package management

if [[ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${MEOW}/lib/package/common.sh"

MAS_PACKAGES_DIR="${MEOW}/packages/mas"

_cache_installed_mas_packages() {
  if [[ -z "${_MAS_INSTALLED_PACKAGES:-}" ]]; then
    action_msg 0 "Caching MAS installed apps..."
    _MAS_INSTALLED_PACKAGES="$(mas list | awk -F'[()]' '{print $2}')"
  fi
}

is_mas_package_installed() {
  _cache_installed_mas_packages
  grep -qE "^$1$" <<<"$_MAS_INSTALLED_PACKAGES"
}

setup_mas() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up mas CLI"
  command -v mas >/dev/null 2>&1 || {
    indented_warning "$indent" "mas CLI not found"
    return 1
  }
  success_tick_msg "$indent" "mas CLI available"
}

install_mas_packages() {
  install_packages_generic "$1" "$2" "mas" "mas install" "is_mas_package_installed"
}

update_mas_packages() {
  update_packages_generic "$1" "$2" "mas" "mas upgrade" "is_mas_package_installed"
}
