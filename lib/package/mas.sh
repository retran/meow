#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_mas_packages() {
  cache_package_list "mas" "mas list | awk -F'[()]' '{print \$2}'"
}

is_mas_package_installed() {
  _cache_installed_mas_packages
  is_package_installed "mas" "$1"
}

setup_mas() {
  step_header "Setting up mas CLI"
  command -v mas >/dev/null 2>&1 || {
    warning "mas CLI not found"
    return 1
  }
  success_tick_msg "mas CLI available"
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
    step_header "Mac App Store Package Removal ($1)"
  fi
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/mas.list"
  if [[ -f "$package_file" ]]; then
    warning "Mac App Store apps cannot be automatically uninstalled via mas CLI"
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      info "Please manually uninstall the following apps through Launchpad or Applications folder:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        [[ -z "$package_name" ]] && continue
        info "  - $package_name"
      done <"$package_file"
    fi
  fi
  return 0
}

cleanup_mas() {
  # Add empty line before cleanup for better grouping
  echo ""

  # Mac App Store doesn't have a built-in cleanup command
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cleaning Mac App Store (no-op)"
    success_tick_msg "Mac App Store cleanup skipped"
  else
    success_tick_msg "Mac App Store cleanup skipped"
  fi
}
