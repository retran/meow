#!/usr/bin/env bash

# lib/core/bash_compat.sh - Bash version compatibility utilities

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

# Get bash version as a comparable integer (e.g., "3.2.57" -> 302)
get_bash_version_number() {
  local version="${BASH_VERSION%%[^0-9.]*}"  # Remove any non-numeric suffix
  local major="${version%%.*}"
  local minor="${version#*.}"
  minor="${minor%%.*}"
  
  # Default to 0 if we can't parse
  major="${major:-0}"
  minor="${minor:-0}"
  
  echo "$((major * 100 + minor))"
}

# Check if bash version meets minimum requirement
check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version=$((required_major * 100 + required_minor))
  local current_version
  
  current_version=$(get_bash_version_number)
  
  if [[ $current_version -ge $required_version ]]; then
    return 0
  else
    return 1
  fi
}

# Display bash version information
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

# Check for bash 3.2 compatibility and show warning if needed
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