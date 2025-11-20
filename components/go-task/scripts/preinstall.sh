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
# @file: components/go-task/scripts/preinstall.sh
# @brief: Configures system package repositories for Task CLI on Linux.
# @author: Andrew Vasilyev
# @license: MIT
#
set -euo pipefail

component="$1"
_meow_root="${2:-}"

os_name="$(uname -s)"
if [ "$os_name" != "Linux" ]; then
  exit 0
fi

_download_and_run() {
  local url="$1"
  local downloader=()

  if command -v curl >/dev/null 2>&1; then
    downloader=(curl -1sLf "$url")
  elif command -v wget >/dev/null 2>&1; then
    downloader=(wget -qO- "$url")
  else
    echo "go-task preinstall for '${component}' requires curl or wget to be installed." >&2
    return 1
  fi

  local runner=(bash)
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      runner=(sudo -E bash)
    else
      echo "Please run the go-task preinstall step as root or install sudo." >&2
      return 1
    fi
  fi

  # shellcheck disable=SC2090
  "${downloader[@]}" | "${runner[@]}"
}

configure_repository() {
  local script_url="$1"
  local manager_name="$2"
  echo "Configuring Task repository for ${manager_name} via ${script_url}"
  _download_and_run "$script_url"
}

if command -v apt-get >/dev/null 2>&1; then
  configure_repository "https://dl.cloudsmith.io/public/task/task/setup.deb.sh" "APT"
elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  configure_repository "https://dl.cloudsmith.io/public/task/task/setup.rpm.sh" "DNF/YUM"
else
  echo "No repository setup script available for this distribution in go-task preinstall."
fi
