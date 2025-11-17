#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/package/apt.sh
# @brief: APT package manager utilities for Debian/Ubuntu package installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\n' -W"
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

setup_apt() {
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_setup "APT"
  fi

  if is_dry_run; then
    dry_run_ui_info "APT: Would check for 'apt-get' command."
    if ! command -v apt-get >/dev/null 2>&1; then
      dry_run_ui_info "APT: 'apt-get' command not found. APT setup would fail."
    else
      dry_run_ui_info "APT: Would update package index to refresh available package information."
      dry_run_ui_info "  Command: sudo apt-get update"
    fi
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    ui_error "APT: 'apt-get' command not found. Cannot set up APT."
    return 1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_spinner "APT: Updating package index" \
      --success "APT: Package index updated successfully." \
      --fail "APT: Failed to update package index." \
      sudo apt-get update
  else
    sudo apt-get update >/dev/null 2>&1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_ready "APT"
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
  if is_dry_run; then
    dry_run_ui_info "APT: Would remove orphaned packages and clear the download cache."
    dry_run_ui_info "  Commands: sudo apt-get autoremove -y && sudo apt-get clean"
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_cleaning "APT"

    ui_spinner "APT: Removing unused packages" \
      --success "APT: Unused packages removed successfully." \
      --fail "APT: Failed to remove unused packages." \
      sudo apt-get autoremove -y

    ui_spinner "APT: Cleaning package cache" \
      --success "APT: Package cache cleaned successfully." \
      --fail "APT: Failed to clean package cache." \
      sudo apt-get clean
  else
    ui_spinner "APT: Cleaning environment" \
      --success "APT: Environment cleaned successfully." \
      --fail "APT: Failed to clean APT environment." \
      bash -c "sudo apt-get autoremove -y && sudo apt-get clean"
  fi
}
