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
# @file: components/time-tracking/scripts/init.sh
# @brief: Initialization script for time tracking applications and configuration.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_COMPONENT_TOGGL_INIT_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_TOGGL_INIT_SOURCED=1

# Set up bash completion
if [ -n "${BASH_VERSION:-}" ] && ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    mapfile -t COMPREPLY < <(env COMP_WORDS="${COMP_WORDS[*]}" COMP_CWORD="$COMP_CWORD" _TOGGL_COMPLETE=complete-bash toggl)
  }
  complete -F _toggl toggl
fi

# Set up zsh completion
if [ -n "${ZSH_VERSION:-}" ] && ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    local current_line="${BUFFER}"
    eval "$(env COMMANDLINE="${current_line}" _TOGGL_COMPLETE=complete-zsh toggl)"
  }

  if type compdef >/dev/null 2>&1; then
    compdef _toggl toggl
  fi
fi
