#!/usr/bin/env bash

# lib/package/pipx.sh - pipx package management

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/package/common.sh"

PIPX_PACKAGES_DIR="${DOTFILES_DIR}/packages/pipx"

# Check if pipx package is installed
pipx_is_installed() {
  local package_name="$1"
  pipx list --short | grep -q "^${package_name} "
}

# Install pipx packages
install_pipx_packages() {
  install_packages_generic "$1" "$2" "pipx" "Pipxfile" "pipx install" "pipx_is_installed"
}

# Update pipx packages
update_pipx_packages() {
  update_packages_generic "$1" "$2" "pipx" "Pipxfile" "pipx upgrade" "pipx_is_installed"
}
