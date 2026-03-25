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
# @file: lib/package/luarocks.sh
# @brief: LuaRocks package manager utilities for Lua rock installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_LUAROCKS_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_LUAROCKS_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_luarocks_packages() {
  local cache_var="_LUAROCKS_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed luarocks packages..."
    local output
    output=$(luarocks list --porcelain 2>/dev/null | awk '{print $1}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached luarocks packages."
  fi
}

is_luarocks_package_installed() {
  _cache_installed_luarocks_packages
  is_package_installed "luarocks" "$1"
}

_resolve_luarocks() {
  if command -v luarocks >/dev/null 2>&1; then
    echo "luarocks"
    return 0
  fi

  # Fall back to luarocks bundled with the mise lua install
  if command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/luarocks" ]; then
      export PATH="$mise_shims_dir:$PATH"
      echo "luarocks"
      return 0
    fi
  fi

  return 1
}

setup_luarocks() {
  ui_package_manager_setup "luarocks"

  if is_dry_run; then
    if ! _resolve_luarocks >/dev/null 2>&1; then
      dry_run_ui_info "luarocks is not found. If this were a real run, luarocks setup would be skipped."
    else
      dry_run_ui_info "luarocks is already available. If this were a real run, no setup would be needed."
    fi
    return 0
  fi

  if ! _resolve_luarocks >/dev/null 2>&1; then
    ui_action_error "luarocks command not found. Please install Lua (via lua-toolchain) to proceed."
    return 1
  fi

  ui_package_manager_ready "luarocks"
}

install_luarocks_packages() {
  if ! _resolve_luarocks >/dev/null 2>&1; then
    ui_action_error "luarocks not found. Please install Lua first."
    return 1
  fi

  install_packages_generic "$1" "luarocks" "luarocks install" "is_luarocks_package_installed"
}

update_luarocks_packages() {
  update_packages_generic "$1" "luarocks" "luarocks install" "is_luarocks_package_installed" \
    "(is already installed|up to date)"
}

uninstall_luarocks_packages() {
  uninstall_packages_generic "$1" "luarocks" "luarocks remove" "is_luarocks_package_installed"
}

cleanup_luarocks() {
  if is_dry_run; then
    dry_run_ui_info "Would clean luarocks cache."
    return 0
  fi

  ui_spinner "Cleaning luarocks cache..." \
    --success "luarocks cache cleaned successfully." \
    --fail "Failed to clean luarocks cache." \
    luarocks purge --old-versions
}
