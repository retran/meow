#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APK_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APK_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_apk_packages() {
  cache_package_list "apk" "apk info"
}

is_apk_package_installed() {
  _cache_installed_apk_packages
  is_package_installed "apk" "$1"
}

setup_apk() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Setting up apk"
  fi

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v apk >/dev/null 2>&1; then
      dry_run_ui_info "apk not found - would fail setup"
    else
      dry_run_ui_info "Would update apk package index"
      dry_run_ui_info "  Command: sudo apk update"
      dry_run_ui_info "  Would refresh available package information"
    fi
    return 0
  fi

  command -v apk >/dev/null 2>&1 || {
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "Updating apk index" \
      --success "apk index updated" \
      --fail "Failed to update apk index" \
      sudo apk update
  else
    sudo apk update >/dev/null 2>&1
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_action_success "apk ready"
  fi
}

install_apk_packages() {
  install_packages_generic "$1" "apk" "sudo apk add --no-cache" "is_apk_package_installed"
}

update_apk_packages() {
  update_packages_generic "$1" "apk" "sudo apk add --no-cache --upgrade" "is_apk_package_installed"
}

uninstall_apk_packages() {
  uninstall_packages_generic "$1" "apk" "sudo apk del" "is_apk_package_installed"
}

cleanup_apk() {
  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "apk cleanup would be skipped (no cache to clean)"
    dry_run_ui_info "  apk uses --no-cache flag so no cleanup needed"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning apk"
    ui_action_success "apk cleanup completed (no cache to clean)"
  else
    # In non-verbose mode, just skip silently since apk doesn't need cleanup
    ui_action_success "apk cleanup completed"
  fi
}
