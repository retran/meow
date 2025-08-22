#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APK_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APK_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_apk_packages() {
  cache_package_list "apk" "apk info"
}

is_apk_package_installed() {
  _cache_installed_apk_packages
  is_package_installed "apk" "$1"
}

setup_apk() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "apk_setting_up")"
  fi

  if is_dry_run; then
    if ! command -v apk >/dev/null 2>&1; then
      dry_run_ui_info "$(get_static_message "apk_not_found_would_fail")"
    else
      dry_run_ui_info "$(get_static_message "apk_would_update_index")"
      dry_run_ui_info "  $(get_static_message "apk_update_command")"
      dry_run_ui_info "  $(get_static_message "apk_would_refresh_info")"
    fi
    return 0
  fi

  command -v apk >/dev/null 2>&1 || {
    ui_error "$(get_static_message "apk_not_found")"
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "$(parse_spinner_messages "apk_update")" \
      sudo apk update
  else
    sudo apk update >/dev/null 2>&1 || {
      ui_error "$(get_static_message "apk_failed_update")"
      return 1
    }
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_action_success "$(get_static_message "apk_setup_complete")"
  fi
}

install_apk_packages() {
  install_packages_generic "$1" "apk" "sudo apk add --no-cache" "is_apk_package_installed"
}

update_apk_packages() {
  update_packages_generic "$1" "apk" "sudo apk add --no-cache --upgrade" "is_apk_package_installed"
}

uninstall_apk_packages() {
  uninstall_packages_generic "$1" "apk" "sudo apk del" "is_apk_package_installed"
}

cleanup_apk() {
  if is_dry_run; then
    dry_run_ui_info "$(get_static_message "apk_cleanup_would_skip")"
    dry_run_ui_info "  $(get_static_message "apk_no_cache_info")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "apk_cleaning")"
    ui_action_success "$(get_static_message "apk_cleanup_completed")"
  else
    ui_action_success "$(get_static_message "apk_cleanup_completed_short")"
  fi
}
