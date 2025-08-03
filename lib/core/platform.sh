#!/usr/bin/env bash

# lib/core/platform.sh - Detect OS once for all scripts

if [[ -n "${_LIB_CORE_PLATFORM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_PLATFORM_SOURCED=1

IS_MACOS=false
IS_DEBIAN_BASED=false
IS_ALPINE=false
IS_ARCH=false

if [[ "$(uname -s)" == "Darwin" ]]; then
  IS_MACOS=true
fi

if [[ -f "/etc/os-release" ]]; then
  # shellcheck disable=SC1091
  source "/etc/os-release"

  # Alpine
  if [[ "${ID,,}" == "alpine" ]]; then
    IS_ALPINE=true
  fi

  # Arch Linux
  if [[ "${ID,,}" == "arch" ]] || [[ "${ID_LIKE,,}" =~ arch ]]; then
    IS_ARCH=true
  fi

  # Debian‐based
  if [[ "${ID_LIKE,,}" =~ debian ]]; then
    IS_DEBIAN_BASED=true
  fi
fi
