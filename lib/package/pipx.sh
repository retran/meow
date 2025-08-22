#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_pipx_packages() {
  cache_package_list "pipx" "pipx list --short 2>/dev/null | awk '{print \$1}'"
}

is_pipx_package_installed() {
  _cache_installed_pipx_packages
  is_package_installed "pipx" "$1"
}

setup_pipx() {
  ui_step_header "Setting up pipx"

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v pipx >/dev/null 2>&1; then
      dry_run_ui_info "pipx not found - would fail setup"
    else
      dry_run_ui_info "pipx already available, no setup needed"
    fi
    return 0
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    ui_action_error "pipx not found"
    return 1
  fi
  ui_action_success "pipx available"
}

install_pipx_packages() {
  install_packages_generic "$1" "pipx" "pipx install" "is_pipx_package_installed"
}

update_pipx_packages() {
  update_packages_generic "$1" "pipx" "pipx upgrade" "is_pipx_package_installed"
}

uninstall_pipx_packages() {
  uninstall_packages_generic "$1" "pipx" "pipx uninstall" "is_pipx_package_installed"
}

cleanup_pipx() {
  # Add empty line before cleanup for better grouping
  echo ""

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "pipx cleanup would be skipped (no cleanup needed)"
    return 0
  fi

  # pipx doesn't have a built-in cleanup command, so we'll skip
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning pipx (no-op)"
    ui_action_success "pipx cleanup skipped"
  else
    ui_action_success "pipx cleanup skipped"
  fi
}
