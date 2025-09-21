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
# @file: components/development-essential/scripts/init.sh
# @brief: Initialization script for essential development tools and environment setup.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED=1

# Git commit message preparation function
_prepare_commit_message() {
  # The original sed '/^/d' command would delete all input,
  # preventing the function from processing the commit message.
  # It has been removed to allow the message content to flow through
  # to the read commands and fmt for proper formatting.
  (
    read -r subject
    echo "$subject"

    read -r empty_line
    echo "$empty_line"

    fmt -s -w 72
  )
}

# AI-assisted git commit function (if meow is available)
if command -v meow >/dev/null 2>&1; then
  mgc() {
    if [ -n "$1" ]; then
      (echo "$1"; echo ""; git diff --staged)
    else
      git diff --staged
    fi | meow g -t commit | _prepare_commit_message | git commit -F - --edit
  }
fi

