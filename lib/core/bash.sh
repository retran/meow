#!/usr/bin/env bash

# Set strict mode for the script.

# Helper function for safe string formatting, sourced from lib/core/ui.sh.
source "${MEOW}/lib/core/ui.sh"

# Guard against multiple sourcing of this file.
if [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

# Extracts the major and minor version number from BASH_VERSION.
# Returns the version as an integer (e.g., 302 for 3.2, 400 for 4.0).
get_bash_version_number() {
  local version
  local major
  local minor

  version="${BASH_VERSION%%[^0-9.]*}"
  major="${version%%.*}"
  minor="${version#*.}"
  minor="${minor%%.*}"

  # Default to 0 if parts are empty (e.g., if BASH_VERSION is malformed)
  major="${major:-0}"
  minor="${minor:-0}"

  echo "$((major * 100 + minor))"
}

# Checks if the current Bash version meets the required minimum.
# Arguments: $1 = required major version, $2 = required minor version.
# Returns 0 for true (meets requirement), 1 for false.
check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version
  local current_version

  required_version=$((required_major * 100 + required_minor))
  current_version=$(get_bash_version_number)

  [[ "$current_version" -ge "$required_version" ]]
}

# Displays information about the current Bash version.
# Adapts output based on whether ui.sh is sourced.
show_bash_version_info() {
  local current_version

  current_version=$(get_bash_version_number)

  if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
    ui_info "$(_f "Bash version: %s (%s)" "${BASH_VERSION}" "$current_version")"

    if check_bash_version 4 0; then
      ui_success "Modern Bash features available"
    else
      ui_warning "Using compatibility mode for Bash 3.2"
    fi
  else
    # Resolved SC2005: _f is assumed to print the formatted string directly.
    # A newline is explicitly added to preserve the behavior of the original 'echo'.
    _f "Bash version: %s (%s)\n" "${BASH_VERSION}" "$current_version"
  fi
}

# Warns if Bash 3.2 compatibility mode is active.
# Adapts output based on whether ui.sh is sourced.
warn_bash_compatibility() {
  if ! check_bash_version 4 0; then
    if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
      ui_info_detail "Running in Bash 3.2 compatibility mode"
      ui_info "Consider upgrading to Bash 4.0+ for optimal performance"
    else
      echo "Running in Bash 3.2 compatibility mode"
      echo "Consider upgrading to Bash 4.0+ for optimal performance"
    fi
  fi
}
