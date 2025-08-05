#!/usr/bin/env bash

# lib/package/vscode.sh - VS Code extension management

if [[ -n "${_LIB_PACKAGE_VSCODE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_VSCODE_SOURCED=1

source "${MEOW}/lib/package/common.sh"

VSCODE_PACKAGES_DIR="${MEOW}/packages/vscode"

_cache_installed_vscode_extensions() {
  if [[ -z "${_VSCODE_INSTALLED_EXTENSIONS:-}" ]]; then
    action_msg 0 "Caching VS Code extensions list..."
    if command -v code >/dev/null 2>&1; then
      _VSCODE_INSTALLED_EXTENSIONS="$(code --list-extensions 2>/dev/null)"
    else
      _VSCODE_INSTALLED_EXTENSIONS=""
    fi
  fi
}

is_vscode_package_installed() {
  _cache_installed_vscode_extensions
  grep -qE "^$1$" <<<"$_VSCODE_INSTALLED_EXTENSIONS"
}

setup_vscode() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up VS Code CLI"
  if ! command -v code >/dev/null 2>&1; then
    indented_warning "$indent" "VS Code CLI not found, skipping extensions"
    return 1
  fi
  success_tick_msg "$indent" "VS Code CLI available"
  return 0
}

install_vscode_packages() {
  local category="$1"
  local indent_level="${2:-1}"

  if ! command -v code >/dev/null 2>&1; then
    indented_info "$indent_level" "VS Code CLI not found, skipping VS Code extension installation"
    return 0
  fi

  install_packages_generic "$category" "$indent_level" "vscode" "code --install-extension" "is_vscode_package_installed"
}

update_vscode_packages() {
  local category="$1"
  local indent_level="${2:-1}"

  if ! command -v code >/dev/null 2>&1; then
    indented_info "$indent_level" "VS Code CLI not found, skipping VS Code extension update"
    return 0
  fi

  update_packages_generic "$category" "$indent_level" "vscode" "code --install-extension" "is_vscode_package_installed"
}
