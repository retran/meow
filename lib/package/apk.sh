#!/usr/bin/env bash

# Guard to prevent multiple sourcing
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
  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "Setting up apk"
  fi

  if is_dry_run; then
    if ! command -v apk >/dev/null 2>&1; then
      dry_run_ui_info "apk not found. Setup would fail."
    else
      dry_run_ui_info "Would update apk package index."
      dry_run_ui_info "  Command: sudo apk update"
      dry_run_ui_info "  This would refresh available package information."
    fi
    return 0
  fi

  command -v apk >/dev/null 2>&1 || {
    ui_error "apk not found. Please ensure apk is installed and in your PATH."
    return 1
  }

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_spinner "Updating apk package index..." \
      sudo apk update || {
      ui_error "Failed to update apk package index."
      return 1
    }
  else
    sudo apk update >/dev/null 2>&1 || {
      ui_error "Failed to update apk package index silently."
      return 1
    }
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_action_success "apk available and package index updated."
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
  if is_dry_run; then
    dry_run_ui_info "apk cleanup would be skipped (no cache to clean)."
    dry_run_ui_info "  apk typically manages its own cache via '--no-cache' during installation, so explicit cleanup is rarely needed."
    return 0
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "Cleaning apk"
  fi
  ui_action_success "apk cleanup completed (no cache to clean)."
}
