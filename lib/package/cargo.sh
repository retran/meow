#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_cargo_packages() {
  cache_package_list "cargo" "cargo install --list 2>/dev/null | awk '/:/ {print \$1}'"
}

is_cargo_package_installed() {
  _cache_installed_cargo_packages
  is_package_installed "cargo" "$1"
}

setup_cargo() {
  ui_step_header "$(get_static_message "cargo_setting_up")"

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v cargo >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "cargo_not_found_would_fail")"
    else
      dry_run_ui_info "$(get_static_message "cargo_already_available")"
    fi
    return 0
  fi

  command -v cargo >/dev/null 2>&1 || {
    ui_action_error "$(get_static_message "cargo_not_found")"
    return 1
  }
  ui_action_success "$(get_static_message "cargo_available")"
}

install_cargo_packages() {
  install_packages_generic "$1" "cargo" "cargo install" "is_cargo_package_installed"
}

update_cargo_packages() {
  update_packages_generic "$1" "cargo" "cargo install --force" "is_cargo_package_installed" \
    "(already installed|Installing)"
}

uninstall_cargo_packages() {
  uninstall_packages_generic "$1" "cargo" "cargo uninstall" "is_cargo_package_installed"
}

cleanup_cargo() {
  # Add empty line before cleanup for better grouping
  echo ""

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "Cargo cleanup would be skipped (no cleanup needed)"
    dry_run_ui_info "  Cargo packages are installed per-user, managed by Rust toolchain"
    return 0
  fi

  # Cargo doesn't have a built-in cleanup command like npm cache clean
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning Cargo (no-op)"
    ui_action_success "Cargo cleanup skipped"
  else
    ui_action_success "Cargo cleanup skipped"
  fi
}
