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
# @file: lib/core/dry_run.sh
# @brief: Dry-run mode utilities for safe operation testing.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/colors.sh"

if [ -n "${_LIB_CORE_DRY_RUN_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_DRY_RUN_SOURCED=1

is_dry_run() {
  [ "${MEOW_DRY_RUN:-}" = "true" ]
}

dry_run_command() {
  local description="$1"
  shift

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would execute: %s" "${description}")"
    return 0
  else
    "$@"
  fi
}

dry_run_info() {
  local message="$1"
  echo -e "  ${CYAN}[DRY-RUN]${RESET} ${message}"
}

dry_run_ui_info() {
  dry_run_info "$@"
}

dry_run_command_info() {
  local command="$1"
  echo -e "  ${CYAN}[DRY-RUN]${RESET}   $(_f "Command: %s" "${NORMAL}${command}${RESET}")"
}

dry_run_file_operation() {
  local operation="$1"
  local target="$2"
  local source_path="${3:-}"

  if is_dry_run; then
    case "$operation" in
      "create_symlink")
        dry_run_ui_info "$(_f "Would create symlink: %s -> %s" "$target" "$source_path")"
        ;;
      "create_dir")
        dry_run_ui_info "$(_f "Would create directory: %s" "$target")"
        ;;
      "remove_file")
        dry_run_ui_info "$(_f "Would remove file: %s" "$target")"
        ;;
      "remove_dir")
        dry_run_ui_info "$(_f "Would remove directory: %s" "$target")"
        ;;
      "backup_file")
        dry_run_ui_info "$(_f "Would backup file: %s" "$target")"
        ;;
      "restore_file")
        dry_run_ui_info "$(_f "Would restore file: %s from %s" "$target" "$source_path")"
        ;;
      *)
        dry_run_ui_info "$(_f "Would perform file operation '%s' on: %s" "$operation" "$target")"
        ;;
    esac
    return 0
  else
    return 1
  fi
}

dry_run_package_operation() {
  local manager="$1"
  local operation="$2"
  local packages="$3"

  if is_dry_run; then
    case "$operation" in
      "install")
        dry_run_ui_info "$(_f "Would install %s packages: %s" "$manager" "$packages")"
        ;;
      "update")
        dry_run_ui_info "$(_f "Would update %s packages: %s" "$manager" "$packages")"
        ;;
      "remove")
        dry_run_ui_info "$(_f "Would remove %s packages: %s" "$manager" "$packages")"
        ;;
      *)
        dry_run_ui_info "$(_f "Would perform %s operation '%s' on packages: %s" "$manager" "$operation" "$packages")"
        ;;
    esac
    return 0
  else
    return 1
  fi
}

dry_run_git_operation() {
  local operation="$1"
  local repo_path="$2"
  local details="${3:-}"

  if is_dry_run; then
    case "$operation" in
      "clone")
        dry_run_ui_info "$(_f "Would clone repository to: %s" "$repo_path")"
        if [ -n "$details" ]; then
          dry_run_ui_info "  $(_f "Repository URL: %s" "$details")"
        fi
        ;;
      "pull")
        dry_run_ui_info "$(_f "Would pull updates in repository: %s" "$repo_path")"
        ;;
      "checkout")
        dry_run_ui_info "$(_f "Would checkout '%s' in repository: %s" "$details" "$repo_path")"
        ;;
      *)
        dry_run_ui_info "$(_f "Would perform git operation '%s' in: %s" "$operation" "$repo_path")"
        ;;
    esac
    return 0
  else
    return 1
  fi
}

dry_run_script_execution() {
  local script_path="$1"
  local description="${2:-$(basename "$script_path")}"

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would execute script: %s" "$description")"
    dry_run_ui_info "$(_f "  Script path: %s" "$script_path")"
    return 0
  else
    return 1
  fi
}
