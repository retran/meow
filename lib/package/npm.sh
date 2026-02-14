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
# @file: lib/package/npm.sh
# @brief: npm package manager utilities for Node.js package installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_npm_packages() {
  local cache_var="_NPM_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed npm packages..."
    local output
    output=$(npm list -g --depth=0 --parseable 2>/dev/null | grep 'node_modules/' | sed 's|.*/node_modules/||' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached npm packages."
  fi
}

is_npm_package_installed() {
  _cache_installed_npm_packages
  is_package_installed "npm" "$1"
}

setup_npm() {
  ui_package_manager_setup "npm"

  if is_dry_run; then
    if ! command -v npm >/dev/null 2>&1; then
      dry_run_ui_info "npm is not found. If this were a real run, npm setup would be skipped."
    else
      dry_run_ui_info "npm is already available. If this were a real run, no setup would be needed."
    fi
    return 0
  fi

  # Add mise shims to PATH if mise is available but npm is not
  if ! command -v npm >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/npm" ]; then
      export PATH="$mise_shims_dir:$PATH"
      ui_verbose_info "Added mise shims to PATH for npm access."
    fi
  fi

  if ! command -v npm >/dev/null 2>&1; then
    ui_action_error "npm command not found. Please install npm (e.g., via Node.js installer) to proceed."
    return 1
  fi
  ui_package_manager_ready "npm"
}

install_npm_packages() {
  # Add mise shims to PATH if mise is available but npm is not in PATH
  if ! command -v npm >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/npm" ]; then
      export PATH="$mise_shims_dir:$PATH"
    fi
  fi
  
  install_packages_generic "$1" "npm" "npm install -g" "is_npm_package_installed"
}

update_npm_packages() {
  update_packages_generic "$1" "npm" "npm update -g" "is_npm_package_installed" \
    "(up to date|already at the latest version)"
}

uninstall_npm_packages() {
  uninstall_packages_generic "$1" "npm" "npm uninstall -g" "is_npm_package_installed"
}

cleanup_npm() {
  if is_dry_run; then
    dry_run_ui_info "Would clean npm cache."
    return 0
  fi

  ui_spinner "Cleaning npm cache..." \
    --success "npm cache cleaned successfully." \
    --fail "Failed to clean npm cache." \
    npm cache clean --force
}
