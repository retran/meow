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
# @file: lib/package/cargo.sh
# @brief: Cargo package manager utilities for Rust crate installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_cargo_packages() {
  local cache_var="_CARGO_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed cargo packages..."
    local output
    output=$(cargo install --list 2>/dev/null | awk '/:/ {print $1}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached cargo packages."
  fi
}

is_cargo_package_installed() {
  _cache_installed_cargo_packages
  is_package_installed "cargo" "$1"
}

setup_cargo() {
  ui_step_header "Setting up Cargo"

  if is_dry_run; then
    if ! command -v cargo >/dev/null 2>&1; then
      dry_run_ui_info "Cargo not found - setup would fail."
    else
      dry_run_ui_info "Cargo already available, ready for package installation."
    fi
    return 0
  fi

  # Add mise shims to PATH if mise is available but cargo is not
  if ! command -v cargo >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/cargo" ]; then
      export PATH="$mise_shims_dir:$PATH"
      ui_verbose_info "Added mise shims to PATH for cargo access."
    fi
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    ui_action_error "Cargo not found. Please install Rust and Cargo."
    return 1
  fi
  ui_action_success "Cargo is available"
}

install_cargo_packages() {
  # Add mise shims to PATH if mise is available but cargo is not in PATH
  if ! command -v cargo >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/cargo" ]; then
      export PATH="$mise_shims_dir:$PATH"
    fi
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    ui_action_error "cargo not found. Please install Rust/Cargo first."
    return 1
  fi
  
  local component="$1"
  local manager_name="cargo"
  local install_cmd=("cargo" "install")
  local check_cmd="is_cargo_package_installed"

  local manager_display_name="Cargo"

  local package_file_override="${PACKAGES_OVERRIDE_FILE:-}"
  local package_file="${package_file_override:-${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list}"
  if [ ! -f "$package_file" ]; then
    return 0
  fi

  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -n "$package_name" ]; then
      ((total_packages++)) || true
    fi
  done <"$package_file"

  if [ "$total_packages" -eq 0 ]; then
    return 0
  fi

  local installed_count=0 already_installed_count=0 failed_count=0

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi

    if "$check_cmd" "$package_name"; then
      ui_verbose_action_success "$(_f "%s %s is already installed." "$manager_display_name" "$package_name")"
      ((already_installed_count++)) || true
    else
      local actual_install_cmd=("${install_cmd[@]}")
      if [ "$IS_MACOS" = "true" ] && [ "$package_name" = "cargo-watch" ]; then
        actual_install_cmd=("RUSTFLAGS=-l framework=AppKit" "${install_cmd[@]}")
      fi

      if is_dry_run; then
        dry_run_package_operation "$manager_display_name" "install" "$package_name"
        ((installed_count++)) || true
        continue
      fi

      if [ "$MEOW_VERBOSE" = "true" ]; then
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by run_package_operation's design
        if run_package_operation \
          "$(_f "Installing %s %s..." "$manager_display_name" "$package_name")" \
          "$(_f "Successfully installed %s %s." "$manager_display_name" "$package_name")" \
          "$(_f "Failed to install %s %s!" "$manager_display_name" "$package_name")" \
          "${actual_install_cmd[@]}" "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by ui_silent_spinner's design
        if ui_silent_spinner "$(_f "Installing %s %s" "$manager_display_name" "$package_name")" "${actual_install_cmd[@]}" "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
          ui_action_error "$(_f "Failed to install %s %s!" "$manager_display_name" "$package_name")"
        fi
      fi
    fi
  done <"$package_file"

  if [ "$failed_count" -eq 0 ]; then
    if [ "$installed_count" -gt 0 ]; then
      ui_indent "$(_f "%s: ✓ %d installed, %d already present" "$(capitalize "$manager_name")" "$installed_count" "$already_installed_count")"
    else
      ui_indent "$(_f "%s: ✓ All %d packages already present" "$(capitalize "$manager_name")" "$already_installed_count")"
    fi
    return 0
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d installed, %d already present" "$(capitalize "$manager_name")" "$failed_count" "$installed_count" "$already_installed_count")"
    return 1
  fi
}

update_cargo_packages() {
  update_packages_generic "$1" "cargo" "cargo install --force" "is_cargo_package_installed" \
    "(already installed|Installing)"
}

uninstall_cargo_packages() {
  uninstall_packages_generic "$1" "cargo" "cargo uninstall" "is_cargo_package_installed"
}

cleanup_cargo() {
  if is_dry_run; then
    dry_run_ui_info "Cargo cleanup would be skipped (no cleanup needed)."
    dry_run_ui_info "  Cargo packages are installed per-user, managed by Rust toolchain."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    ui_step_header "Cleaning Cargo"
  fi
  ui_action_success "Cargo cleanup skipped (no-op)."
}
