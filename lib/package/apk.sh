#!/usr/bin/env bash

# lib/package/apk.sh - Alpine apk package management

if [[ -n "${_LIB_PACKAGE_APK_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APK_SOURCED=1

source "${MEOW}/lib/package/common.sh"

APK_PACKAGES_DIR="${MEOW}/packages/apk"

_cache_installed_apk_packages() {
  if [[ -z "${_APK_INSTALLED_PACKAGES:-}" ]]; then
    action_msg 0 "Caching apk package list..."
    _APK_INSTALLED_PACKAGES="$(apk info)"
  fi
}

is_apk_package_installed() {
  _cache_installed_apk_packages
  grep -qE "^$1$" <<<"$_APK_INSTALLED_PACKAGES"
}

setup_apk() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up Alpine apk"
  command -v apk >/dev/null 2>&1 || {
    indented_error_msg "$indent" "apk not found"
    return 1
  }
  ui_spinner "$((indent + 1))" "Updating apk index" \
    --success "apk index updated" \
    --fail "Failed to update apk index" \
    sudo apk update
  success_tick_msg "$indent" "apk ready"
}

install_apk_packages() {
  install_packages_generic "$1" "$2" "apk" "sudo apk add --no-cache" "is_apk_package_installed"
}

update_apk_packages() {
  update_packages_generic "$1" "$2" "apk" "sudo apk add --no-cache --upgrade" "is_apk_package_installed"
}

cleanup_apk() {
  local indent="${1:-0}"
  step_header "$indent" "Cleaning apk (no-op)"
  success_tick_msg "$indent" "apk cleanup skipped"
}
