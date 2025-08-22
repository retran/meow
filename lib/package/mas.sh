#!/usr/bin/env bash

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
  ui_step_header "$(get_static_message "mas_setting_up")"

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v mas >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "mas_not_found_would_fail")"
    else
      dry_run_ui_info "$(get_static_message "mas_already_available")"
    fi
    return 0
  fi

  command -v mas >/dev/null 2>&1 || {
    ui_warning "$(get_static_message 'mas_not_found')"
    return 1
  }
  ui_action_success "$(get_static_message "mas_cli_available")"
}

install_mas_packages() {
  install_packages_generic "$1" "mas" "mas install" "is_mas_package_installed"
}

update_mas_packages() {
  update_packages_generic "$1" "mas" "mas upgrade" "is_mas_package_installed"
}

uninstall_mas_packages() {
  # mas CLI не поддерживает удаление приложений, поэтому просто информируем об этом
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Mac App Store Package Removal ($1)"
  fi
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/mas.list"
  if [[ -f "$package_file" ]]; then
    ui_warning "Mac App Store apps cannot be automatically uninstalled via mas CLI"
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
  # Add empty line before cleanup for better grouping
  echo ""

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "Mac App Store cleanup would be skipped (no cleanup needed)"
    dry_run_ui_info "  App Store manages downloads automatically"
    return 0
  fi

  # Mac App Store doesn't have a built-in cleanup command
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "Cleaning Mac App Store (no-op)"
    ui_action_success "Mac App Store cleanup skipped"
  else
    ui_action_success "Mac App Store cleanup skipped"
  fi
}
