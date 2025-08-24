#!/usr/bin/env bash

# Library guard to prevent multiple sourcing
if [[ -n "${_LIB_CORE_PLATFORM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_PLATFORM_SOURCED=1

# Strict mode: exit on error, unset variables, and pipeline failures.
# Note: set -e will affect the sourcing script if this file is sourced.

IS_MACOS=false
IS_DEBIAN_BASED=false
IS_ALPINE=false
IS_ARCH=false

# Detect macOS
if [[ "$(uname -s)" = "Darwin" ]]; then
  IS_MACOS=true
fi

# Detect Linux distribution details from /etc/os-release
if [[ -f "/etc/os-release" ]]; then
  # shellcheck disable=SC1091
  source "/etc/os-release"

  # Convert ID to lowercase using tr for Bash 3.2 compatibility
  # (Bash 4+ has "${ID,,}")
  ID_LOWER="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"

  # Check if ID_LIKE is set before processing
  if [[ -n "${ID_LIKE+x}" ]]; then
    # Convert ID_LIKE to lowercase using tr for Bash 3.2 compatibility
    ID_LIKE_LOWER="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
  else
    ID_LIKE_LOWER=""
  fi

  # Alpine Linux
  if [[ "$ID_LOWER" = "alpine" ]]; then
    IS_ALPINE=true
  fi

  # Arch Linux (including derivatives with ID_LIKE containing 'arch')
  if [[ "$ID_LOWER" = "arch" ]]; then
    IS_ARCH=true
  else
    # Use case for Bash 3.2 pattern matching
    case "$ID_LIKE_LOWER" in
      *"arch"*)
        IS_ARCH=true
        ;;
    esac
  fi

  # Debian-based Linux (including derivatives with ID_LIKE containing 'debian')
  # Use case for Bash 3.2 pattern matching
  case "$ID_LIKE_LOWER" in
    *"debian"*)
      IS_DEBIAN_BASED=true
      ;;
  esac
fi

# Get normalized platform name for component compatibility
get_platform() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}
