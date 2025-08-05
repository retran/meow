#!/usr/bin/env bash

# lib/package/cargo.sh - Cargo package management

if [[ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/package/common.sh"

CARGO_PACKAGES_DIR="${MEOW}/packages/cargo"

_cache_installed_cargo_packages() {
  if [[ -z "${_CARGO_INSTALLED_PACKAGES:-}" ]]; then
    action_msg 0 "Caching Cargo package list..."
    _CARGO_INSTALLED_PACKAGES="$(cargo install --list 2>/dev/null | awk '/:/ {print $1}')"
  fi
}

is_cargo_package_installed() {
  _cache_installed_cargo_packages
  grep -qE "^$1$" <<< "$_CARGO_INSTALLED_PACKAGES"
}

setup_cargo() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up Cargo"
  command -v cargo >/dev/null 2>&1 || {
    indented_error_msg "$indent" "cargo not found"
    return 1
  }
  success_tick_msg "$indent" "Cargo available"
}

install_cargo_packages() {
  install_packages_generic "$1" "$2" "cargo" "cargo install" "is_cargo_package_installed"
}

update_cargo_packages() {
  update_packages_generic "$1" "$2" "cargo" "cargo install --force" "is_cargo_package_installed" \
    "(already installed|Installing)"
}

