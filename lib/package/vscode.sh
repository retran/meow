#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_VSCODE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_VSCODE_SOURCED=1

source "${MEOW}/lib/package/common.sh"

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
  step_header "Setting up VS Code CLI"
  if ! command -v code >/dev/null 2>&1; then
    warning "VS Code CLI not found, skipping extensions"
    return 1
  fi
  success_tick_msg "VS Code CLI available"
  return 0
}

install_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    info "VS Code CLI not found, skipping VS Code extension installation"
    return 0
  fi

  install_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}

update_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    info "VS Code CLI not found, skipping VS Code extension update"
    return 0
  fi

  update_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}
