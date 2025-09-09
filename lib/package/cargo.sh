#!/usr/bin/env bash
# @file:    lib/package/cargo.sh
# @brief:   Package manager abstraction and installation utilities.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_cargo_packages() {
  local cache_var="_CARGO_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed cargo packages..."
    local output
    output=$(cargo install --list 2>/dev/null | awk '/:/ {print $1}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached cargo packages."
  fi
}

is_cargo_package_installed() {
  _cache_installed_cargo_packages
  is_package_installed "cargo" "$1"
}

setup_cargo() {
  ui_step_header "Setting up Cargo"

  if is_dry_run; then
    if ! command -v cargo >/dev/null 2>&1; then
      dry_run_ui_info "Cargo not found - setup would fail."
    else
      dry_run_ui_info "Cargo already available, ready for package installation."
    fi
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    ui_action_error "Cargo not found. Please install Rust and Cargo."
    return 1
  fi
  ui_action_success "Cargo is available"
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
  if is_dry_run; then
    dry_run_ui_info "Cargo cleanup would be skipped (no cleanup needed)."
    dry_run_ui_info "  Cargo packages are installed per-user, managed by Rust toolchain."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    ui_step_header "Cleaning Cargo"
  fi
  ui_action_success "Cargo cleanup skipped (no-op)."
}
