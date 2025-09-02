#!/usr/bin/env bash

if [ -n "${_LIB_CORE_PLATFORM_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_PLATFORM_SOURCED=1

IS_MACOS=false
IS_DEBIAN_BASED=false
IS_ALPINE=false
IS_ARCH=false

if [ "$(uname -s)" = "Darwin" ]; then
  IS_MACOS=true
fi

if [ -f "/etc/os-release" ]; then
  # shellcheck disable=SC1091
  . "/etc/os-release"

  ID_LOWER="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"

  if [ -n "${ID_LIKE+x}" ]; then
    ID_LIKE_LOWER="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
  else
    ID_LIKE_LOWER=""
  fi

  if [ "$ID_LOWER" = "alpine" ]; then
    IS_ALPINE=true
  fi

  if [ "$ID_LOWER" = "arch" ]; then
    IS_ARCH=true
  else
    case "$ID_LIKE_LOWER" in
      *"arch"*)
        IS_ARCH=true
        ;;
    esac
  fi

  case "$ID_LIKE_LOWER" in
    *"debian"*)
      IS_DEBIAN_BASED=true
      ;;
  esac
fi

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
