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
# @file: lib/package/snap.sh
# @brief: Snap package manager helpers for Ubuntu-based distributions.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_SNAP_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_SNAP_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_snap_packages() {
  cache_package_list "snap" "snap list | awk 'NR>1 {print \$1}'"
}

is_snap_package_installed() {
  _cache_installed_snap_packages
  is_package_installed "snap" "$1"
}

_parse_snap_line() {
  local line="$1"
  local parsed
  parsed=$(parse_package_line "$line")
  if [ -z "$parsed" ]; then
    return 1
  fi
  SNAP_PACKAGE_ARGS=()
  while IFS=' ' read -r token; do
    [ -n "$token" ] || continue
    SNAP_PACKAGE_ARGS+=("$token")
  done <<<"$parsed"
  if [ ${#SNAP_PACKAGE_ARGS[@]} -eq 0 ]; then
    return 1
  fi
  SNAP_PACKAGE_NAME="${SNAP_PACKAGE_ARGS[0]}"
  SNAP_PACKAGE_FLAGS=("${SNAP_PACKAGE_ARGS[@]:1}")
  return 0
}

_run_snap_operation() {
  local action="$1"
  shift
  local cmd=("$@")

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_spinner "$(_f "snap %s %s" "$action" "$SNAP_PACKAGE_NAME")" \
      --success "$(_f "Snap %s succeeded for %s." "$action" "$SNAP_PACKAGE_NAME")" \
      --fail "$(_f "Snap %s failed for %s." "$action" "$SNAP_PACKAGE_NAME")" \
      "${cmd[@]}"
  else
    "${cmd[@]}" >/dev/null 2>&1
  fi
}

install_snap_packages() {
  local component="$1"
  local file="${MEOW_COMPONENTS_DIR}/${component}/packages/snap.list"

  if [ ! -f "$file" ]; then
    return 0
  fi

  if ! command -v snap >/dev/null 2>&1; then
    ui_error "Snap command not found. Install snapd to use snap packages."
    return 1
  fi

  local installed_count=0
  local already_count=0
  local failed_count=0

  while IFS= read -r line; do
    if ! _parse_snap_line "$line"; then
      continue
    fi

    if is_snap_package_installed "$SNAP_PACKAGE_NAME"; then
      ui_verbose_action_success "$(_f "Snap %s already installed." "$SNAP_PACKAGE_NAME")"
      ((already_count++)) || true
      continue
    fi

    if is_dry_run; then
      dry_run_package_operation "Snap" "install" "$SNAP_PACKAGE_NAME"
      ((installed_count++)) || true
      continue
    fi

    if _run_snap_operation "install" sudo snap install "$SNAP_PACKAGE_NAME" "${SNAP_PACKAGE_FLAGS[@]}"; then
      ((installed_count++)) || true
    else
      ((failed_count++)) || true
    fi
  done <"$file"

  if [ "$failed_count" -eq 0 ]; then
    ui_indent "$(_f "Snap: ✓ %d installed, %d already present" "$installed_count" "$already_count")"
    return 0
  fi

  ui_indent "$(_f "Snap: ✗ %d failed, %d installed, %d already present" "$failed_count" "$installed_count" "$already_count")"
  return 1
}

update_snap_packages() {
  local component="$1"
  local file="${MEOW_COMPONENTS_DIR}/${component}/packages/snap.list"

  if [ ! -f "$file" ] || ! command -v snap >/dev/null 2>&1; then
    return 0
  fi

  local updated_count=0
  local up_to_date_count=0
  local failed_count=0

  while IFS= read -r line; do
    if ! _parse_snap_line "$line"; then
      continue
    fi

    if ! is_snap_package_installed "$SNAP_PACKAGE_NAME"; then
      ui_action_warning "$(_f "Snap package %s not installed, skipping update." "$SNAP_PACKAGE_NAME")"
      continue
    fi

    if is_dry_run; then
      dry_run_package_operation "Snap" "update" "$SNAP_PACKAGE_NAME"
      ((updated_count++)) || true
      continue
    fi

    if _run_snap_operation "refresh" sudo snap refresh "$SNAP_PACKAGE_NAME"; then
      ((updated_count++)) || true
    else
      ((failed_count++)) || true
    fi
  done <"$file"

  if [ "$failed_count" -eq 0 ]; then
    ui_indent "$(_f "Snap: ✓ %d refreshed, %d up-to-date" "$updated_count" "$up_to_date_count")"
    return 0
  fi

  ui_indent "$(_f "Snap: ✗ %d failed, %d refreshed" "$failed_count" "$updated_count")"
  return 1
}

uninstall_snap_packages() {
  local component="$1"
  local file="${MEOW_COMPONENTS_DIR}/${component}/packages/snap.list"

  if [ ! -f "$file" ] || ! command -v snap >/dev/null 2>&1; then
    return 0
  fi

  local removed_count=0
  local missing_count=0
  local failed_count=0

  while IFS= read -r line; do
    if ! _parse_snap_line "$line"; then
      continue
    fi

    if ! is_snap_package_installed "$SNAP_PACKAGE_NAME"; then
      ((missing_count++)) || true
      continue
    fi

    if is_dry_run; then
      dry_run_package_operation "Snap" "remove" "$SNAP_PACKAGE_NAME"
      ((removed_count++)) || true
      continue
    fi

    if _run_snap_operation "remove" sudo snap remove "$SNAP_PACKAGE_NAME"; then
      ((removed_count++)) || true
    else
      ((failed_count++)) || true
    fi
  done <"$file"

  if [ "$failed_count" -eq 0 ]; then
    ui_indent "$(_f "Snap: ✓ %d removed, %d not installed" "$removed_count" "$missing_count")"
    return 0
  fi

  ui_indent "$(_f "Snap: ✗ %d failed, %d removed, %d not installed" "$failed_count" "$removed_count" "$missing_count")"
  return 1
}
