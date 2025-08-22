#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_VSCODE_SOURCED:-}" ]]; then
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
  ui_step_header "$(get_static_message "vscode_setting_up")"

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v code >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "vscode_cli_not_found_would_warn")"
    else
      dry_run_ui_info "$(get_static_message "vscode_cli_already_available")"
    fi
    return 0
  fi

  if ! command -v code >/dev/null 2>&1; then
    ui_warning "$(get_static_message "vscode_cli_not_found_skip")"
    return 1
  fi
  ui_action_success "$(get_static_message "vscode_cli_available")"
  return 0
}

install_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "$(get_static_message "vscode_cli_not_found_extension_skip")"
    return 0
  fi

  install_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}

update_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "VS Code CLI not found, skipping VS Code extension update"
    return 0
  fi

  update_packages_generic "$component" "vscode" "code --install-extension" "is_vscode_package_installed"
}

uninstall_vscode_packages() {
  local component="$1"

  if ! command -v code >/dev/null 2>&1; then
    ui_info "VS Code CLI not found, skipping VS Code extension uninstall"
    return 0
  fi

  uninstall_packages_generic "$component" "vscode" "code --uninstall-extension" "is_vscode_package_installed"
}

cleanup_vscode() {
  # Add empty line before cleanup for better grouping
  echo ""

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "VS Code cleanup would be skipped (no cleanup needed)"
    dry_run_ui_info "  Extensions are managed by VS Code automatically"
    return 0
  fi

  # VS Code doesn't have a built-in cleanup command for extensions
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning VS Code (no-op)"
    ui_action_success "VS Code cleanup skipped"
  else
    ui_action_success "VS Code cleanup skipped"
  fi
}
