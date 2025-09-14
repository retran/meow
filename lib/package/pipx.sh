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
# @file: lib/package/pipx.sh
# @brief: pipx utilities for isolated Python application installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_pipx_packages() {
  local cache_var="_PIPX_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed pipx packages..."
    local output
    output=$(pipx list --short 2>/dev/null | awk '{print $1}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached pipx packages."
  fi
}

is_pipx_package_installed() {
  _cache_installed_pipx_packages
  is_package_installed "pipx" "$1"
}

setup_pipx() {
  ui_step_header "Setting up pipx"

  if is_dry_run; then
    if ! command -v pipx >/dev/null 2>&1; then
      dry_run_ui_info "pipx not found. Setup would fail."
    else
      dry_run_ui_info "pipx already available. No setup needed."
    fi
    return 0
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    ui_action_error "pipx not found. Please install pipx."
    return 1
  fi
  ui_action_success "pipx is available."
}

install_pipx_packages() {
  install_packages_generic "$1" "pipx" "pipx install" "is_pipx_package_installed"
}

update_pipx_packages() {
  update_packages_generic "$1" "pipx" "pipx upgrade" "is_pipx_package_installed"
}

uninstall_pipx_packages() {
  uninstall_packages_generic "$1" "pipx" "pipx uninstall" "is_pipx_package_installed"
}

cleanup_pipx() {
  if is_dry_run; then
    dry_run_ui_info "pipx cleanup would be skipped (no operation needed)."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ]; then
    ui_step_header "Cleaning pipx (no operation)"
    ui_action_success "pipx cleanup skipped."
  else
    ui_action_success "pipx cleanup skipped."
  fi
}
