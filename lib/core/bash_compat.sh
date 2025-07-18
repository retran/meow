#!/usr/bin/env bash

# lib/core/bash_compat.sh - Bash version compatibility utilities
#
# Provides functions for detecting bash version and ensuring compatibility across
# different bash versions, particularly focusing on macOS default bash 3.2.
#
# Key functions:
# - Version detection and comparison
# - Compatibility warnings and information display
# - Environment-specific behavior adaptation

# Prevent multiple sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

#======================================
# Version Detection and Comparison
#======================================

# Convert bash version string to comparable integer format
# Usage: get_bash_version_number
# Returns: Integer version (e.g., "3.2.57" -> 302, "4.1.0" -> 401)
# Example: version=$(get_bash_version_number)
get_bash_version_number() {
  local version="${BASH_VERSION%%[^0-9.]*}"  # Strip non-numeric suffixes
  local major="${version%%.*}"                # Extract major version
  local minor="${version#*.}"                 # Extract minor part
  minor="${minor%%.*}"                        # Get only minor number
  
  # Provide safe defaults for parsing errors
  major="${major:-0}"
  minor="${minor:-0}"
  
  # Return major*100 + minor for easy comparison
  echo "$((major * 100 + minor))"
}

# Check if current bash version meets minimum requirements
# Usage: check_bash_version <major> [minor]
# Arguments:
#   major - Required major version (default: 3)
#   minor - Required minor version (default: 2)
# Returns: 0 if version meets requirement, 1 otherwise
# Example: if check_bash_version 4 0; then echo "Modern bash"; fi
check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version=$((required_major * 100 + required_minor))
  local current_version
  
  current_version=$(get_bash_version_number)
  
  [[ $current_version -ge $required_version ]]
}

#======================================
# User Information and Warnings
#======================================

# Display comprehensive bash version information
# Usage: show_bash_version_info [indent_level]
# Arguments:
#   indent_level - Display indentation depth (default: 0)
show_bash_version_info() {
  local indent_level="${1:-0}"
  local current_version
  
  current_version=$(get_bash_version_number)
  
  # Use UI functions if available, fall back to plain echo
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

# Display compatibility warning for older bash versions
# Usage: warn_bash_compatibility [indent_level]
# Arguments:
#   indent_level - Display indentation depth (default: 0)
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