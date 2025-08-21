#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_npm_packages() {
  cache_package_list "npm" "npm list -g --depth=0 --parseable 2>/dev/null | sed 's|.*/||;s/@.*//'"
}

is_npm_package_installed() {
  _cache_installed_npm_packages
  is_package_installed "npm" "$1"
}

setup_npm() {
  step_header "Setting up npm"
  if ! command -v npm >/dev/null 2>&1; then
    error_msg "npm not found"
    return 1
  fi
  success_tick_msg "npm available"
}

install_npm_packages() {
  install_packages_generic "$1" "npm" "npm install -g" "is_npm_package_installed"
}

update_npm_packages() {
  update_packages_generic "$1" "npm" "npm update -g" "is_npm_package_installed" \
    "(up to date|already at the latest version)"
}
