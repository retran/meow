#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

get_bash_version_number() {
  local version="${BASH_VERSION%%[^0-9.]*}"
  local major="${version%%.*}"
  local minor="${version#*.}"
  minor="${minor%%.*}"

  major="${major:-0}"
  minor="${minor:-0}"

  echo "$((major * 100 + minor))"
}

check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version=$((required_major * 100 + required_minor))
  local current_version

  current_version=$(get_bash_version_number)

  [[ $current_version -ge $required_version ]]
}

show_bash_version_info() {
  local current_version

  current_version=$(get_bash_version_number)

  if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
    ui_info "Bash version: ${BASH_VERSION} (${current_version})"

    if check_bash_version 4 0; then
      ui_success "Modern bash features available"
    else
      ui_warning "Using compatibility mode for bash 3.2"
    fi
  else
    echo "Bash version: ${BASH_VERSION} (${current_version})"
  fi
}

warn_bash_compatibility() {
  if ! check_bash_version 4 0; then
    if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
      ui_info_detail "Running in bash 3.2 compatibility mode"
      ui_info "Consider upgrading to bash 4.0+ for optimal performance"
    else
      echo "INFO: Running in bash 3.2 compatibility mode"
      echo "      Consider upgrading to bash 4.0+ for optimal performance"
    fi
  fi
}
