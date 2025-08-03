#!/usr/bin/env bash

# lib/package/pipx.sh - pipx package management

if [[ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${MEOW}/lib/package/common.sh"

PIPX_PACKAGES_DIR="${MEOW}/packages/pipx"

_cache_installed_pipx_packages() {
  if [[ -z "${_PIPX_INSTALLED_PACKAGES:-}" ]]; then
    action_msg "${1:-0}" "Caching pipx package list..."
    _PIPX_INSTALLED_PACKAGES="$(pipx list --short 2>/dev/null | awk '{print $1}')"
  fi
}

is_pipx_package_installed() {
  _cache_installed_pipx_packages
  grep -qE "^$1$" <<<"$_PIPX_INSTALLED_PACKAGES"
}

setup_pipx() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up pipx"
  command -v pipx >/dev/null 2>&1 || {
    indented_error_msg "$indent" "pipx not found"
    return 1
  }
  success_tick_msg "$indent" "pipx available"
}

install_pipx_packages() {
  install_packages_generic "$1" "$2" "pipx" "pipx install" "is_pipx_package_installed"
}

update_pipx_packages() {
  update_packages_generic "$1" "$2" "pipx" "pipx upgrade" "is_pipx_package_installed"
}
