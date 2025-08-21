#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_cargo_packages() {
  cache_package_list "cargo" "cargo install --list 2>/dev/null | awk '/:/ {print \$1}'"
}

is_cargo_package_installed() {
  _cache_installed_cargo_packages
  is_package_installed "cargo" "$1"
}

setup_cargo() {
  step_header "Setting up Cargo"
  command -v cargo >/dev/null 2>&1 || {
    error_msg "cargo not found"
    return 1
  }
  success_tick_msg "Cargo available"
}

install_cargo_packages() {
  install_packages_generic "$1" "cargo" "cargo install" "is_cargo_package_installed"
}

update_cargo_packages() {
  update_packages_generic "$1" "cargo" "cargo install --force" "is_cargo_package_installed" \
    "(already installed|Installing)"
}

uninstall_cargo_packages() {
  uninstall_packages_generic "$1" "cargo" "cargo uninstall" "is_cargo_package_installed"
}
