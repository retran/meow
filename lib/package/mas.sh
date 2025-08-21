#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_mas_packages() {
  cache_package_list "mas" "mas list | awk -F'[()]' '{print \$2}'"
}

is_mas_package_installed() {
  _cache_installed_mas_packages
  is_package_installed "mas" "$1"
}

setup_mas() {
  step_header "Setting up mas CLI"
  command -v mas >/dev/null 2>&1 || {
    warning "mas CLI not found"
    return 1
  }
  success_tick_msg "mas CLI available"
}

install_mas_packages() {
  install_packages_generic "$1" "mas" "mas install" "is_mas_package_installed"
}

update_mas_packages() {
  update_packages_generic "$1" "mas" "mas upgrade" "is_mas_package_installed"
}
