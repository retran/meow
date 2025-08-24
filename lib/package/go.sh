#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

is_go_package_installed() {
  local pkg="$1"
  local bin
  bin="$(basename "$pkg" | sed 's/@.*//')"
  command -v "$bin" >/dev/null 2>&1
}

setup_go() {
  ui_step_header "$(fmt "go_setting_up")"

  if is_dry_run; then
    if ! command -v go >/dev/null 2>&1; then
      dry_run_ui_info "$(fmt "go_not_found_would_fail")"
    else
      dry_run_ui_info "$(fmt "go_already_available")"
    fi
    return 0
  fi

  command -v go >/dev/null 2>&1 || {
    ui_action_error "$(fmt 'go_not_found')"
    return 1
  }
  ui_action_success "$(fmt "go_available")"
}

install_go_packages() {
  install_packages_generic "$1" "go" "go install" "is_go_package_installed"
}

update_go_packages() {
  update_packages_generic "$1" "go" "go install" "is_go_package_installed" \
    "(go: installing executables|go: no module dependencies)"
}

uninstall_go_packages() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(fmt "go_package_removal_header" "$1")"
  fi
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/go.list"
  if [[ -f "$package_file" ]]; then
    ui_warning "$(fmt "go_packages_cannot_uninstall")"
    ui_info "$(fmt "go_packages_manual_removal")"

    local go_bin_path=""
    if command -v go >/dev/null 2>&1; then
      go_bin_path="$(go env GOPATH)/bin"
    else
      go_bin_path="${GOPATH:-$HOME/go}/bin"
    fi

    while IFS= read -r line; do
      local package_name
      package_name=$(parse_package_line "$line")
      [[ -z "$package_name" ]] && continue
      local bin
      bin="$(basename "$package_name" | sed 's/@.*//')"
      local binary_path="$go_bin_path/$bin"
      if [[ -f "$binary_path" ]]; then
        ui_info "  rm \"$binary_path\""
      fi
    done <"$package_file"
  fi
  return 0
}

cleanup_go() {
  if is_dry_run; then
    dry_run_ui_info "$(fmt "go_cleanup_would_skip")"
    dry_run_ui_info "  $(fmt "go_modules_managed_by_go")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(fmt "go_cleaning_noop")"
    ui_action_success "$(fmt "go_cleanup_skipped")"
  else
    ui_action_success "$(fmt "go_cleanup_skipped")"
  fi
}
