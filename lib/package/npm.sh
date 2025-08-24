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
      dry_run_ui_info "$(fmt "npm_not_found_would_fail")"
    else
      dry_run_ui_info "$(fmt "npm_already_available")"
    fi
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    ui_action_error "$(fmt 'npm_not_found')"
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
  parse_spinner_messages "npm_cache_clean" >/dev/null
  ui_spinner "$SPINNER_PROGRESS" \
    --success "$SPINNER_SUCCESS" \
    --fail "$SPINNER_FAIL" \
    npm cache clean --force
}
