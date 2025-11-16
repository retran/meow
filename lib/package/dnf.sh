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
# @file: lib/package/dnf.sh
# @brief: DNF/YUM package manager utilities for RPM-based distributions.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_DNF_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_DNF_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_get_dnf_command() {
  if command -v dnf >/dev/null 2>&1; then
    echo "dnf"
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    echo "yum"
    return 0
  fi
  return 1
}

_cache_installed_dnf_packages() {
  cache_package_list "dnf" "rpm -qa --qf '%{NAME}\n' 2>/dev/null"
}

is_dnf_package_installed() {
  _cache_installed_dnf_packages
  is_package_installed "dnf" "$1"
}

setup_dnf() {
  local dnf_cmd
  dnf_cmd=$(_get_dnf_command) || {
    ui_error "DNF/YUM command not found. Cannot manage RPM packages."
    return 1
  }

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_setup "DNF"
  fi

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would update %s package metadata." "$dnf_cmd")"
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_spinner "$(_f "%s: Updating package metadata" "$dnf_cmd")" \
      --success "$(_f "%s: Package metadata updated successfully." "$dnf_cmd")" \
      --fail "$(_f "%s: Failed to update package metadata." "$dnf_cmd")" \
      sudo "$dnf_cmd" makecache -y
  else
    sudo "$dnf_cmd" makecache -y >/dev/null 2>&1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_ready "DNF"
  fi
}

install_dnf_packages() {
  local dnf_cmd
  dnf_cmd=$(_get_dnf_command) || {
    ui_error "DNF/YUM command not available for installation."
    return 1
  }
  install_packages_generic "$1" "dnf" "sudo $dnf_cmd install -y" "is_dnf_package_installed"
}

update_dnf_packages() {
  local dnf_cmd
  dnf_cmd=$(_get_dnf_command) || {
    ui_error "DNF/YUM command not available for updates."
    return 1
  }
  update_packages_generic "$1" "dnf" "sudo $dnf_cmd upgrade -y" "is_dnf_package_installed"
}

uninstall_dnf_packages() {
  local dnf_cmd
  dnf_cmd=$(_get_dnf_command) || {
    ui_error "DNF/YUM command not available for removal."
    return 1
  }
  uninstall_packages_generic "$1" "dnf" "sudo $dnf_cmd remove -y" "is_dnf_package_installed"
}

cleanup_dnf() {
  local dnf_cmd
  dnf_cmd=$(_get_dnf_command) || return 0

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would run %s autoremove." "$dnf_cmd")"
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_cleaning "DNF"
    ui_spinner "$(_f "%s: Removing unused packages" "$dnf_cmd")" \
      --success "$(_f "%s: Unused packages removed." "$dnf_cmd")" \
      --fail "$(_f "%s: Failed to remove unused packages." "$dnf_cmd")" \
      sudo "$dnf_cmd" autoremove -y
  else
    sudo "$dnf_cmd" autoremove -y >/dev/null 2>&1
  fi
}
