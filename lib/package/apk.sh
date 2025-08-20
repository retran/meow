#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APK_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APK_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_apk_packages() {
  cache_package_list "apk" "apk info"
}

is_apk_package_installed() {
  _cache_installed_apk_packages
  is_package_installed "apk" "$1"
}

setup_apk() {
  step_header "Setting up Alpine apk"
  command -v apk >/dev/null 2>&1 || {
    error_msg "apk not found"
    return 1
  }
  ui_spinner "Updating apk index" \
    --success "apk index updated" \
    --fail "Failed to update apk index" \
    sudo apk update
  success_tick_msg "apk ready"
}

install_apk_packages() {
  APK_PACKAGES_DIR="${MEOW}/packages/apk"
  install_packages_generic "$1" "apk" "sudo apk add --no-cache" "is_apk_package_installed"
}

update_apk_packages() {
  APK_PACKAGES_DIR="${MEOW}/packages/apk"
  update_packages_generic "$1" "apk" "sudo apk add --no-cache --upgrade" "is_apk_package_installed"
}

cleanup_apk() {
  step_header "Cleaning apk (no-op)"
  success_tick_msg "apk cleanup skipped"
}
