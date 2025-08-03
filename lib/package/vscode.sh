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
    action_msg "${1:-0}" "Caching VS Code extensions list..."
    _VSCODE_INSTALLED_EXTENSIONS="$(code --list-extensions 2>/dev/null)"
  fi
}

is_vscode_package_installed() {
  _cache_installed_vscode_extensions
  grep -qE "^$1$" <<< "$_VSCODE_INSTALLED_EXTENSIONS"
}

setup_vscode() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up VS Code CLI"
  command -v code >/dev/null 2>&1 || {
    indented_warning "$indent" "VS Code CLI not found, skipping extensions"
    return 1
  }
  success_tick_msg "$indent" "VS Code CLI available"
}

install_vscode_packages() {
  install_packages_generic "$1" "$2" "vscode" "code --install-extension" "is_vscode_package_installed"
}

update_vscode_packages() {
  update_packages_generic "$1" "$2" "vscode" "code --install-extension" "is_vscode_package_installed"
}

