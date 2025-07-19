#!/usr/bin/env bash

# lib/core/bash.sh - Bash version compatibility utilities

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

# Convert bash version to integer for comparison
get_bash_version_number() {
  local version="${BASH_VERSION%%[^0-9.]*}"
  local major="${version%%.*}"
  local minor="${version#*.}"
  minor="${minor%%.*}"

  major="${major:-0}"
  minor="${minor:-0}"

  echo "$((major * 100 + minor))"
}

# Check if bash version meets requirements
check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version=$((required_major * 100 + required_minor))
  local current_version

  current_version=$(get_bash_version_number)

  [[ $current_version -ge $required_version ]]
}

# Show bash version info
show_bash_version_info() {
  local indent_level="${1:-0}"
  local current_version

  current_version=$(get_bash_version_number)

  if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
    info "$indent_level" "Bash version: ${BASH_VERSION} (${current_version})"

    if check_bash_version 4 0; then
      success "$indent_level" "Modern bash features available"
    else
      warning "$indent_level" "Using compatibility mode for bash 3.2"
    fi
  else
    echo "Bash version: ${BASH_VERSION} (${current_version})"
  fi
}

# Show compatibility warning for old bash
warn_bash_compatibility() {
  local indent_level="${1:-0}"

  if ! check_bash_version 4 0; then
    if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
      info_italic_msg "$indent_level" "Running in bash 3.2 compatibility mode"
      indented_info "$indent_level" "Consider upgrading to bash 4.0+ for optimal performance"
    else
      echo "INFO: Running in bash 3.2 compatibility mode"
      echo "      Consider upgrading to bash 4.0+ for optimal performance"
    fi
  fi
}
