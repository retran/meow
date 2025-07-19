#!/usr/bin/env bash

# lib/package/npm.sh - npm package management

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/common.sh"

# Install npm packages
install_npm_packages() {
  install_packages_generic "$1" "$2" "npm" "npmfile" "npm install -g" "npm list -g --depth=0"
}

# Update npm packages
update_npm_packages() {
  update_packages_generic "$1" "$2" "npm" "npmfile" "npm update -g" "npm list -g --depth=0" "(up to date|already at the latest version)"
}

# Set up npm
setup_npm() {
  local indent="${1:-0}"

  if ! command -v npm >/dev/null 2>&1; then
    step_header "$indent" "Setting up npm"

    if command -v node >/dev/null 2>&1; then
      indented_warning "$indent" "Node.js is available but npm is not found in PATH"
      return 1
    else
      indented_warning "$indent" "Node.js and npm are not installed. This should be handled by homebrew packages."
      return 1
    fi
  fi

  success_tick_msg "$indent" "npm is available"
  return 0
}
