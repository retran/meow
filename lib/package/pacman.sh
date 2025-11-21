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
# @file: lib/package/pacman.sh
# @brief: Pacman package manager utilities for Arch Linux package installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_PACMAN_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_PACMAN_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_pacman_packages() {
  cache_package_list "pacman" "pacman -Qq"
}

is_pacman_package_installed() {
  _cache_installed_pacman_packages
  grep -qE "^$1$" <<<"${_PACMAN_INSTALLED_PACKAGES}"
}

setup_pacman() {
  if is_dry_run; then
    dry_run_ui_info "Would check for pacman installation and sync package database."
    if ! command -v pacman >/dev/null 2>&1; then
      dry_run_ui_info "pacman not found - setup would fail."
    else
      dry_run_ui_info "Command: sudo pacman -Sy"
      dry_run_ui_info "This would refresh available package information."
    fi
    return 0
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    ui_error "pacman not found. Please install pacman to proceed."
    return 1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "Setting up pacman"
    ui_spinner "Syncing pacman package database..." sudo pacman -Sy
    ui_action_success "pacman ready"
  else
    ui_spinner "Syncing pacman package database..." sudo pacman -Sy || {
      ui_error "Failed to sync pacman database."
      return 1
    }
  fi
}

install_pacman_packages() {
  install_packages_generic "$1" "pacman" "sudo pacman -S --noconfirm" "is_pacman_package_installed"
}

update_pacman_packages() {
  update_packages_generic "$1" "pacman" "sudo pacman -Syu --noconfirm" "is_pacman_package_installed"
}

uninstall_pacman_packages() {
  uninstall_packages_generic "$1" "pacman" "sudo pacman -R --noconfirm" "is_pacman_package_installed"
}

cleanup_pacman() {
  if is_dry_run; then
    dry_run_ui_info "Would clean pacman package cache."
    dry_run_ui_info "Command: sudo pacman -Sc --noconfirm"
    dry_run_ui_info "This would remove cached packages not currently installed."
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "Cleaning pacman cache"
  fi
  ui_spinner "Pruning pacman cache..." sudo pacman -Sc --noconfirm
}
