#!/usr/bin/env bash

# Helper function for safe string formatting, injected by the inliner script.
_f() {
  local template="$1"
  shift
  printf -- "$template" "$@"
}

if [[ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_mas_packages() {
  cache_package_list "mas" "mas list | awk -F'[()]' '{print \$2}'"
}

is_mas_package_installed() {
  _cache_installed_mas_packages
  is_package_installed "mas" "$1"
}

setup_mas() {
  ui_step_header "Setting up mas CLI"

  if is_dry_run; then
    if ! command -v mas >/dev/null 2>&1; then
      dry_run_ui_info "mas CLI not found - would warn and fail setup"
    else
      dry_run_ui_info "mas CLI already available, no setup needed"
    fi
    return 0
  fi

  command -v mas >/dev/null 2>&1 || {
    ui_warning "mas CLI not found"
    return 1
  }
  ui_action_success "mas CLI available"
}

install_mas_packages() {
  install_packages_generic "$1" "mas" "mas install" "is_mas_package_installed"
}

update_mas_packages() {
  update_packages_generic "$1" "mas" "mas upgrade" "is_mas_package_installed"
}

uninstall_mas_packages() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(_f "TODO: write message - mas_package_removal_header" "$1")"
  fi
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/mas.list"
  if [[ -f "$package_file" ]]; then
    ui_warning "App Store apps cannot be automatically uninstalled via mas CLI"
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      ui_info "Please manually uninstall the following apps through Launchpad or Applications folder:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        [[ -z "$package_name" ]] && continue
        ui_info "  - $package_name"
      done <"$package_file"
    fi
  fi
  return 0
}

cleanup_mas() {
  if is_dry_run; then
    dry_run_ui_info "App Store cleanup would be skipped (no cleanup needed)"
    dry_run_ui_info "  App Store manages downloads automatically"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning App Store (no-op)"
    ui_action_success "App Store cleanup skipped"
  else
    ui_action_success "App Store cleanup skipped"
  fi
}
