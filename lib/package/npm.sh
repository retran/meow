#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_npm_packages() {

  cache_package_list "npm" "npm list -g --depth=0 --parseable 2>/dev/null | sed 's|.*/||;s/@.*//'"
}

is_npm_package_installed() {

  _cache_installed_npm_packages
  is_package_installed "npm" "$1"
}

setup_npm() {

  ui_package_manager_setup "npm"

  if is_dry_run; then
    if ! command -v npm >/dev/null 2>&1; then
      dry_run_ui_info "npm is not found. If this were a real run, npm setup would be skipped."
    else
      dry_run_ui_info "npm is already available. If this were a real run, no setup would be needed."
    fi
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    ui_action_error "npm command not found. Please install npm (e.g., via Node.js installer) to proceed."
    return 1
  fi
  ui_package_manager_ready "npm"
}

install_npm_packages() {

  install_packages_generic "$1" "npm" "npm install -g" "is_npm_package_installed"
}

update_npm_packages() {

  update_packages_generic "$1" "npm" "npm update -g" "is_npm_package_installed" \
    "(up to date|already at the latest version)"
}

uninstall_npm_packages() {

  uninstall_packages_generic "$1" "npm" "npm uninstall -g" "is_npm_package_installed"
}

cleanup_npm() {

  if is_dry_run; then
    dry_run_ui_info "Would clean npm cache."
    return 0
  fi

  ui_spinner "Cleaning npm cache..." \
    --success "npm cache cleaned successfully." \
    --fail "Failed to clean npm cache." \
    npm cache clean --force
}
