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
# @file: components/docker-desktop/scripts/env.sh
# @brief: Environment configuration script for Docker Desktop and container tools.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED=1

if [ -f "$HOME/.orbstack/shell/init.zsh" ]; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    printf "INFO: Sourcing OrbStack init file: %s\n" "$HOME/.orbstack/shell/init.zsh"
  fi

  if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
    source "$HOME/.orbstack/shell/init.zsh"
  else
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      printf "DRY-RUN: Would source OrbStack init file: %s\n" "$HOME/.orbstack/shell/init.zsh"
    fi
  fi
fi
