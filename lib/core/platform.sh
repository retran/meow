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
