#!/usr/bin/env bash
# This script manages macOS App Store (mas) packages.

source "${MEOW}/lib/core/ui.sh"

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
      dry_run_ui_info "mas CLI not found. If this were a real run, setup would fail."
    else
      dry_run_ui_info "mas CLI available. No setup action needed."
    fi
    return 0
  fi

  if ! command -v mas >/dev/null 2>&1; then
    ui_warning "mas CLI not found. Please install 'mas' to manage App Store apps."
    return 1
  fi
  ui_action_success "mas CLI available."
}

install_mas_packages() {
  install_packages_generic "$1" "mas" "mas install" "is_mas_package_installed"
}

update_mas_packages() {
  update_packages_generic "$1" "mas" "mas upgrade" "is_mas_package_installed"
}

uninstall_mas_packages() {
  local component_name="$1"
  local package_file="${MEOW_COMPONENTS_DIR}/${component_name}/packages/mas.list"

  if is_dry_run; then
    dry_run_ui_info "Processing App Store apps for uninstallation from component '${component_name}' (dry run)."
    if [[ -f "$package_file" ]]; then
      dry_run_ui_info "  App Store apps cannot be automatically uninstalled via mas CLI."
      dry_run_ui_info "  The following apps would need manual uninstallation:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        if [[ -n "$package_name" ]]; then
          dry_run_ui_info "    - ${package_name}"
        fi
      done <"$package_file"
    else
      dry_run_ui_info "  No App Store apps file found for component '${component_name}'. No apps to uninstall."
    fi
    return 0
  fi

  if [[ "${MEOW_VERBOSE:-}" = "true" ]]; then
    ui_step_header "Uninstalling App Store apps for component '${component_name}'"
  fi

  if [[ -f "$package_file" ]]; then
    ui_warning "App Store apps cannot be automatically uninstalled via mas CLI."
    if [[ "${MEOW_VERBOSE:-}" = "true" ]]; then
      ui_info "Please manually uninstall the following apps through Launchpad or the Applications folder:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        if [[ -n "$package_name" ]]; then
          ui_info "  - ${package_name}"
        fi
      done <"$package_file"
    fi
  else
    if [[ "${MEOW_VERBOSE:-}" = "true" ]]; then
      ui_info "No App Store apps file found for component '${component_name}'. Nothing to uninstall."
    fi
  fi
  return 0
}

cleanup_mas() {
  if is_dry_run; then
    dry_run_ui_info "App Store cleanup would be skipped (no cleanup needed)."
    dry_run_ui_info "  App Store manages downloads and updates automatically."
    return 0
  fi

  if [[ "${MEOW_VERBOSE:-}" = "true" ]]; then
    ui_step_header "Cleaning App Store (no-op)"
  fi
  ui_action_success "App Store cleanup skipped (managed automatically)."
}
