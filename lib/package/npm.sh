#!/usr/bin/env bash

# lib/package/npm.sh - npm package management

if [[ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${MEOW}/lib/package/common.sh"

NPM_PACKAGES_DIR="${MEOW}/packages/npm"

_cache_installed_npm_packages() {
  if [[ -z "${_NPM_INSTALLED_PACKAGES:-}" ]]; then
    action_msg "${1:-0}" "Caching npm package list..."
    _NPM_INSTALLED_PACKAGES="$(
      npm list -g --depth=0 --parseable 2>/dev/null |
        sed 's|.*/||;s/@.*//'
    )"
  fi
}

is_npm_package_installed() {
  _cache_installed_npm_packages
  grep -qE "^$1$" <<<"$_NPM_INSTALLED_PACKAGES"
}

setup_npm() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up npm"
  command -v npm >/dev/null 2>&1 || {
    indented_error_msg "$indent" "npm not found"
    return 1
  }
  success_tick_msg "$indent" "npm available"
}

install_npm_packages() {
  install_packages_generic "$1" "$2" "npm" "npm install -g" "is_npm_package_installed"
}

update_npm_packages() {
  update_packages_generic "$1" "$2" "npm" "npm update -g" "is_npm_package_installed" \
    "(up to date|already at the latest version)"
}
