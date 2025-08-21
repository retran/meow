#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\\n' -W 2>/dev/null"
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

setup_apt() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    package_manager_setup_msg "APT"
  fi

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v apt-get >/dev/null 2>&1; then
      dry_run_info "apt-get not found - would fail setup"
    else
      dry_run_info "Would update APT package index"
      dry_run_info "  Command: sudo apt-get update"
      dry_run_info "  Would refresh available package information"
    fi
    return 0
  fi

  command -v apt-get >/dev/null 2>&1 || {
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "Updating APT index" \
      --success "APT index updated" \
      --fail "Failed to update APT index" \
      sudo apt-get update
  else
    sudo apt-get update >/dev/null 2>&1
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    package_manager_ready_msg "APT"
  fi
}

install_apt_packages() {
  install_packages_generic "$1" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

update_apt_packages() {
  update_packages_generic "$1" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

uninstall_apt_packages() {
  uninstall_packages_generic "$1" "apt" "sudo apt-get remove -y" "is_apt_package_installed"
}

cleanup_apt() {
  # Handle dry-run mode
  if is_dry_run; then
    dry_run_info "Would clean APT package cache and remove unused packages"
    dry_run_info "  Commands: sudo apt-get autoremove -y && sudo apt-get clean"
    dry_run_info "  Would remove orphaned packages and clear download cache"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    package_manager_cleaning_msg "APT"
    ui_spinner "Removing unused packages" \
      --success "APT autoremove completed" \
      --fail "APT autoremove failed" \
      sudo apt-get autoremove -y
    ui_spinner "Cleaning cache" \
      --success "APT cleanup completed" \
      --fail "APT cleanup failed" \
      sudo apt-get clean
  else
    ui_spinner "Cleaning APT" \
      --success "APT cleanup completed" \
      --fail "APT cleanup failed" \
      bash -c "sudo apt-get autoremove -y && sudo apt-get clean"
  fi
}
