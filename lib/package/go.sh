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
# @file: lib/package/go.sh
# @brief: Go module utilities for Go package installation and dependency management.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

if [ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

is_go_package_installed() {
  local pkg="$1"
  local bin
  bin="$(basename "$pkg" | sed 's/@.*//')"
  command -v "$bin" >/dev/null 2>&1
}

setup_go() {
  ui_step_header "Setting up Go"

  if is_dry_run; then
    if ! command -v go >/dev/null 2>&1; then
      dry_run_ui_info "Go is not found in PATH. Setup would fail without the 'go' command."
    else
      dry_run_ui_info "Go is already available. Ready for package installation."
    fi
    return 0
  fi

  if ! command -v go >/dev/null 2>&1; then
    ui_action_error "Go command not found in PATH."
    return 1
  else
    ui_action_success "Go command available."
  fi
}

install_go_packages() {
  install_packages_generic "$1" "go" "go install" "is_go_package_installed"
}

update_go_packages() {
  update_packages_generic "$1" "go" "go install" "is_go_package_installed" \
    "(go: installing executables|go: no module dependencies)"
}

uninstall_go_packages() {
  ui_step_header "$(_f "Go Package Removal (%s)" "$1")"
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/go.list"

  if [ -f "$package_file" ]; then
    ui_warning "Go packages cannot be automatically uninstalled via the 'go' command."
    ui_info "Go packages are typically installed to GOPATH/bin. Please manually remove the binaries if needed:"

    local go_bin_path=""
    if command -v go >/dev/null 2>&1; then
      go_bin_path="$(go env GOPATH)/bin"
    else
      go_bin_path="${GOPATH:-$HOME/go}/bin"
    fi

    while IFS= read -r line; do
      local package_name
      package_name=$(parse_package_line "$line")
      [ -z "$package_name" ] && continue

      local bin
      bin="$(basename "$package_name" | sed 's/@.*//')"
      local binary_path="$go_bin_path/$bin"

      if [ -f "$binary_path" ]; then
        ui_info "  Would consider removing: \"$binary_path\""
      fi
    done <"$package_file"
  else
    ui_info "No Go package list found for component '$1'."
  fi
  return 0
}

cleanup_go() {
  if is_dry_run; then
    dry_run_ui_info "Go cleanup would be skipped (no explicit cleanup mechanism needed)."
    dry_run_ui_info "  Go modules are cached in GOMODCACHE, which Go manages automatically."
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "Cleaning Go (no-operation)"
  fi
  ui_action_success "Go cleanup skipped; Go manages its own caches automatically."
}
