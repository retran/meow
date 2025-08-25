#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

if [ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

get_bash_version_number() {
  local version
  local major
  local minor

  version="${BASH_VERSION%%[^0-9.]*}"
  major="${version%%.*}"
  minor="${version#*.}"
  minor="${minor%%.*}"

  major="${major:-0}"
  minor="${minor:-0}"

  echo $((major * 100 + minor))
}

check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version
  local current_version

  required_version=$((required_major * 100 + required_minor))
  current_version=$(get_bash_version_number)

  [ "$current_version" -ge "$required_version" ]
}

show_bash_version_info() {
  local current_version

  current_version=$(get_bash_version_number)

  if [ -n "${_LIB_CORE_UI_SOURCED:-}" ]; then
    ui_info "$(_f "Bash version: %s (%s)" "${BASH_VERSION}" "$current_version")"

    if check_bash_version 4 0; then
      ui_success "Modern Bash features available"
    else
      ui_warning "Using compatibility mode for Bash 3.2"
    fi
  else
    _f "Bash version: %s (%s)\n" "${BASH_VERSION}" "$current_version"
  fi
}

warn_bash_compatibility() {
  if ! check_bash_version 4 0; then
    if [ -n "${_LIB_CORE_UI_SOURCED:-}" ]; then
      ui_info_detail "Running in Bash 3.2 compatibility mode"
      ui_info "Consider upgrading to Bash 4.0+ for optimal performance"
    else
      echo "Running in Bash 3.2 compatibility mode"
      echo "Consider upgrading to Bash 4.0+ for optimal performance"
    fi
  fi
}
