#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/core/platform.sh
# @brief: Platform detection and system-specific utilities.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_CORE_PLATFORM_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_PLATFORM_SOURCED=1

IS_MACOS=false
IS_ALPINE=false
IS_ARCH=false
IS_RPM_BASED=false

MEOW_OS_ID=""
MEOW_OS_VERSION_ID=""
MEOW_OS_ID_LIKE=""

if [ "$(uname -s)" = "Darwin" ]; then
  IS_MACOS=true
fi

if [ -f "/etc/os-release" ]; then
  # shellcheck disable=SC1091
  . "/etc/os-release"

  MEOW_OS_ID="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"
  MEOW_OS_VERSION_ID="$(echo "${VERSION_ID:-}" | tr '[:upper:]' '[:lower:]')"
  MEOW_OS_ID_LIKE="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"

  if [ "$MEOW_OS_ID" = "alpine" ]; then
    IS_ALPINE=true
  fi

  if [ "$MEOW_OS_ID" = "arch" ]; then
    IS_ARCH=true
  else
    case "$MEOW_OS_ID_LIKE" in
      *"arch"*)
        IS_ARCH=true
        ;;
    esac
  fi

  case "$MEOW_OS_ID" in
    rhel | centos | rocky | almalinux | fedora)
      IS_RPM_BASED=true
      ;;
    *)
      case "$MEOW_OS_ID_LIKE" in
        *"rhel"* | *"fedora"* | *"centos"* | *"rocky"* | *"almalinux"*)
          IS_RPM_BASED=true
          ;;
      esac
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

meow_os_is() {
  local needle
  needle="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  [ -n "$needle" ] && [ "$MEOW_OS_ID" = "$needle" ]
}

meow_os_is_like() {
  local needle token
  needle="$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')"
  if [ -z "$needle" ]; then
    return 1
  fi
  if meow_os_is "$needle"; then
    return 0
  fi
  for token in $MEOW_OS_ID_LIKE; do
    if [ "$token" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

meow_os_matches_any() {
  local needle
  for needle in "$@"; do
    if meow_os_is_like "$needle"; then
      return 0
    fi
  done
  return 1
}
