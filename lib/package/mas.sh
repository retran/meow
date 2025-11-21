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
# @file: lib/package/mas.sh
# @brief: Mac App Store command line utilities for macOS app installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

if [ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

# Set default value for MEOW_ENABLE_MAS if not already set
: "${MEOW_ENABLE_MAS:=true}"

_cache_installed_mas_packages() {
  local cache_var="_MAS_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed mas packages..."
    local output
    output=$(mas list | awk '{print $1}' 2>/dev/null || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached mas packages."
  fi
}

is_mas_package_installed() {
  _cache_installed_mas_packages
  is_package_installed "mas" "$1"
}

setup_mas() {
  ui_step_header "Setting up mas CLI"

  if [[ "$MEOW_ENABLE_MAS" != "true" ]]; then
    ui_info "mas setup skipped (MEOW_ENABLE_MAS is not set to 'true')."
    return 0
  fi

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

_install_mas_package_helper() {
  local package_id
  package_id=$(awk '{print $1}' <<<"$1")
  mas install "$package_id"
}

install_mas_packages() {
  if [[ "$MEOW_ENABLE_MAS" != "true" ]]; then
    ui_info "mas package installation skipped (MEOW_ENABLE_MAS is not set to 'true')."
    return 0
  fi

  install_packages_generic "$1" "mas" "_install_mas_package_helper" "is_mas_package_installed"
}

update_mas_packages() {
  if [[ "$MEOW_ENABLE_MAS" != "true" ]]; then
    ui_info "mas package update skipped (MEOW_ENABLE_MAS is not set to 'true')."
    return 0
  fi

  update_packages_generic "$1" "mas" "mas upgrade" "is_mas_package_installed"
}

uninstall_mas_packages() {
  if [[ "$MEOW_ENABLE_MAS" != "true" ]]; then
    ui_info "mas package uninstallation skipped (MEOW_ENABLE_MAS is not set to 'true')."
    return 0
  fi

  local component_name="$1"
  local package_file="${MEOW_COMPONENTS_DIR}/${component_name}/packages/mas.list"

  if is_dry_run; then
    dry_run_ui_info "Processing App Store apps for uninstallation from component '${component_name}' (dry run)."
    if [ -f "$package_file" ]; then
      dry_run_ui_info "  App Store apps cannot be automatically uninstalled via mas CLI."
      dry_run_ui_info "  The following apps would need manual uninstallation:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        if [ -n "$package_name" ]; then
          dry_run_ui_info "    - ${package_name}"
        fi
      done <"$package_file"
    else
      dry_run_ui_info "  No App Store apps file found for component '${component_name}'. No apps to uninstall."
    fi
    return 0
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ]; then
    ui_step_header "Uninstalling App Store apps for component '${component_name}'"
  fi

  if [ -f "$package_file" ]; then
    ui_warning "App Store apps cannot be automatically uninstalled via mas CLI."
    if [ "${MEOW_VERBOSE:-}" = "true" ]; then
      ui_info "Please manually uninstall the following apps through Launchpad or the Applications folder:"
      while IFS= read -r line; do
        local package_name
        package_name=$(parse_package_line "$line")
        if [ -n "$package_name" ]; then
          ui_info "  - ${package_name}"
        fi
      done <"$package_file"
    fi
  else
    if [ "${MEOW_VERBOSE:-}" = "true" ]; then
      ui_info "No App Store apps file found for component '${component_name}'. Nothing to uninstall."
    fi
  fi
  return 0
}

cleanup_mas() {
  if [[ "$MEOW_ENABLE_MAS" != "true" ]]; then
    ui_info "mas cleanup skipped (MEOW_ENABLE_MAS is not set to 'true')."
    return 0
  fi

  if is_dry_run; then
    dry_run_ui_info "App Store cleanup would be skipped (no cleanup needed)."
    dry_run_ui_info "  App Store manages downloads and updates automatically."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ]; then
    ui_step_header "Cleaning App Store (no-op)"
  fi
  ui_action_success "App Store cleanup skipped (managed automatically)."
}
