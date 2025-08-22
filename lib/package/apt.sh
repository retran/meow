#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\\n' -W 2>/dev/null"
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

setup_apt() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_package_manager_setup "APT"
  fi

  # Handle dry-run mode
  if is_dry_run; then
    if ! command -v apt-get >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "apt_get_not_found")"
    else
      dry_run_ui_info "$(get_static_message "apt_would_update_index")"
      dry_run_ui_info "  $(get_static_message "apt_update_command")"
      dry_run_ui_info "  $(get_static_message "apt_would_refresh_info")"
    fi
    return 0
  fi

  command -v apt-get >/dev/null 2>&1 || {
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "$(get_static_message "apt_updating_index")" \
      --success "$(get_static_message "apt_index_updated")" \
      --fail "$(get_static_message "apt_index_update_failed")" \
      sudo apt-get update
  else
    sudo apt-get update >/dev/null 2>&1
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_package_manager_ready "APT"
  fi
}

install_apt_packages() {
  install_packages_generic "$1" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

update_apt_packages() {
  update_packages_generic "$1" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

uninstall_apt_packages() {
  uninstall_packages_generic "$1" "apt" "sudo apt-get remove -y" "is_apt_package_installed"
}

cleanup_apt() {
  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "$(get_static_message "apt_would_clean_cache")"
    dry_run_ui_info "  $(get_static_message "apt_cleanup_commands")"
    dry_run_ui_info "  $(get_static_message "apt_would_remove_orphaned")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_package_manager_cleaning "APT"
    parse_spinner_messages "apt_remove_unused"
    ui_spinner "$SPINNER_PROGRESS" \
      --success "$SPINNER_SUCCESS" \
      --fail "$SPINNER_FAIL" \
      sudo apt-get autoremove -y
    parse_spinner_messages "apt_clean_cache"
    ui_spinner "$SPINNER_PROGRESS" \
      --success "$SPINNER_SUCCESS" \
      --fail "$SPINNER_FAIL" \
      sudo apt-get clean
  else
    parse_spinner_messages "apt_cleanup"
    ui_spinner "$SPINNER_PROGRESS" \
      --success "$SPINNER_SUCCESS" \
      --fail "$SPINNER_FAIL" \
      bash -c "sudo apt-get autoremove -y && sudo apt-get clean"
  fi
}
