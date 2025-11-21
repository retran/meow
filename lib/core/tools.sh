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
# @file: lib/core/tools.sh
# @brief: Tool availability checking and dependency management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/platform.sh"

# Detect operating system using POSIX-compliant uname
_detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "darwin" ;;
    *) echo "unknown" ;;
  esac
}

# Detect CPU architecture using POSIX-compliant uname
_detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64) echo "arm64" ;;
    armv7l) echo "arm" ;;
    *) echo "unknown" ;;
  esac
}

# Get installation directory with fallback
_get_install_dir() {
  if [ -w "/usr/local/bin" ] 2>/dev/null; then
    echo "/usr/local/bin"
  elif [ -w "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    echo "$HOME/.local/bin"
  else
    echo ""
  fi
}
