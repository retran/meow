#!/usr/bin/env bash

if [ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

# Caches the list of installed pipx packages.
_cache_installed_pipx_packages() {
  cache_package_list "pipx" "pipx list --short 2>/dev/null | awk '{print \$1}'"
}

# Checks if a given pipx package is installed.
# Arguments:
#   $1 - The name of the pipx package to check.
is_pipx_package_installed() {
  _cache_installed_pipx_packages
  is_package_installed "pipx" "$1"
}

# Sets up pipx, ensuring it's available.
setup_pipx() {
  ui_step_header "Setting up pipx"

  if is_dry_run; then
    if ! command -v pipx >/dev/null 2>&1; then
      dry_run_ui_info "pipx not found. Would fail setup."
    else
      dry_run_ui_info "pipx already available. No setup needed."
    fi
    return 0
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    ui_action_error "pipx not found. Please install pipx."
    return 1
  fi
  ui_action_success "pipx is available."
}

# Installs pipx packages.
# Arguments:
#   $1 - The list of pipx packages to install (space-separated string).
install_pipx_packages() {
  install_packages_generic "$1" "pipx" "pipx install" "is_pipx_package_installed"
}

# Updates pipx packages.
# Arguments:
#   $1 - The list of pipx packages to update (space-separated string).
update_pipx_packages() {
  update_packages_generic "$1" "pipx" "pipx upgrade" "is_pipx_package_installed"
}

# Uninstalls pipx packages.
# Arguments:
#   $1 - The list of pipx packages to uninstall (space-separated string).
uninstall_pipx_packages() {
  uninstall_packages_generic "$1" "pipx" "pipx uninstall" "is_pipx_package_installed"
}

# Performs cleanup for pipx.
cleanup_pipx() {
  if is_dry_run; then
    dry_run_ui_info "pipx cleanup would be skipped (no operation needed)."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ]; then
    ui_step_header "Cleaning pipx (no operation)"
    ui_action_success "pipx cleanup skipped."
  else
    ui_action_success "pipx cleanup skipped."
  fi
}
