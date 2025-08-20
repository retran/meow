#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_PLATFORM_SOURCED:-}" ]]; then
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

  ID_LOWER="${ID,,}"

  if [[ -n "${ID_LIKE+x}" ]]; then
    ID_LIKE_LOWER="${ID_LIKE,,}"
  else
    ID_LIKE_LOWER=""
  fi

  # Alpine
  if [[ "$ID_LOWER" == "alpine" ]]; then
    IS_ALPINE=true
  fi

  # Arch Linux
  if [[ "$ID_LOWER" == "arch" || "$ID_LIKE_LOWER" == *"arch"* ]]; then
    IS_ARCH=true
  fi

  # Debian-based
  if [[ "$ID_LIKE_LOWER" == *"debian"* ]]; then
    IS_DEBIAN_BASED=true
  fi
fi
