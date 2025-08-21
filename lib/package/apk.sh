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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Setting up apk"
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
    success_tick_msg "apk ready"
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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cleaning apk"
    success_tick_msg "apk cleanup completed (no cache to clean)"
  else
    # In non-verbose mode, just skip silently since apk doesn't need cleanup
    success_tick_msg "apk cleanup completed"
  fi
}
