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
# @file: lib/package/vscode.sh
# @brief: Visual Studio Code extension management utilities for IDE customization.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_VSCODE_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_VSCODE_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_vscode_extensions() {
  if command -v code >/dev/null 2>&1; then
    cache_package_list "vscode" "code --list-extensions 2>/dev/null"
  fi
}

is_vscode_package_installed() {
  _cache_installed_vscode_extensions
  is_package_installed "vscode" "$1"
}

setup_vscode() {
  ui_step_header "Setting up VS Code CLI"

  if is_dry_run; then
    if ! command -v code >/dev/null 2>&1; then
      dry_run_ui_info "VS Code CLI not found. If installed, ensure it's in your PATH."
      dry_run_ui_info "Skipping VS Code extension management."
    else
      dry_run_ui_info "VS Code CLI is available, ready for extension installation."
    fi
    return 0
  fi

  if ! command -v code >/dev/null 2>&1; then
    ui_warning "VS Code CLI not found. Please install it and ensure it's in your PATH to manage extensions."
    ui_warning "Skipping VS Code extension management."
    return 1
  fi
  ui_action_success "VS Code CLI available."
  return 0
}

install_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "VS Code CLI not found, skipping VS Code extension installation for component '$component'."
    return 0
  fi

  install_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}

update_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "VS Code CLI not found, skipping VS Code extension update for component '$component'."
    return 0
  fi

  update_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}

uninstall_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "VS Code CLI not found, skipping VS Code extension uninstallation for component '$component'."
    return 0
  fi

  uninstall_packages_generic "$component" "vscode" "code --uninstall-extension" "is_vscode_package_installed"
}

cleanup_vscode() {
  if is_dry_run; then
    dry_run_ui_info "VS Code cleanup would be skipped (extensions are managed automatically by VS Code)."
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "Cleaning VS Code (no-op)"
    ui_action_success "VS Code cleanup skipped (extensions are managed automatically by VS Code)."
  else
    ui_action_success "VS Code cleanup skipped."
  fi
}
