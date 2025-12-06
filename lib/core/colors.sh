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
# @file: lib/core/colors.sh
# @brief: Color definitions and terminal styling for consistent UI output.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_CORE_COLORS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_COLORS_SOURCED=1

MEOW_TPUT_SUPPORTED=0
if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
  MEOW_TPUT_SUPPORTED=1
fi
export MEOW_TPUT_SUPPORTED

if [ -t 1 ]; then
  if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
    NORMAL="\033[38;2;192;202;245m"
    RED="\033[38;2;247;118;142m"
    GREEN="\033[38;2;158;206;106m"
    YELLOW="\033[38;2;224;175;104m"
    BLUE="\033[38;2;122;162;247m"
    MAGENTA="\033[38;2;187;154;247m"
    CYAN="\033[38;2;125;207;255m"
    ORANGE="\033[38;2;255;158;100m"
    WHITE_BOLD="\033[1m${NORMAL}"
    MAGENTA_BOLD="\033[1m${MAGENTA}"
    CYAN_BOLD="\033[1m${CYAN}"
    BOLD="\033[1m"
    RESET="\033[0m"
  elif [ "$MEOW_TPUT_SUPPORTED" -eq 1 ]; then
    NORMAL="$(tput setaf 254 2>/dev/null)"
    RED="$(tput setaf 210 2>/dev/null)"
    GREEN="$(tput setaf 150 2>/dev/null)"
    YELLOW="$(tput setaf 222 2>/dev/null)"
    BLUE="$(tput setaf 111 2>/dev/null)"
    MAGENTA="$(tput setaf 183 2>/dev/null)"
    CYAN="$(tput setaf 117 2>/dev/null)"
    ORANGE="$(tput setaf 215 2>/dev/null)"

    WHITE_BOLD="$(tput bold 2>/dev/null)${NORMAL}"
    MAGENTA_BOLD="$(tput bold 2>/dev/null)${MAGENTA}"
    CYAN_BOLD="$(tput bold 2>/dev/null)${CYAN}"

    BOLD="$(tput bold 2>/dev/null)"
    RESET="$(tput sgr0 2>/dev/null)"
  else
    NORMAL=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    ORANGE=""

    WHITE_BOLD=""
    MAGENTA_BOLD=""
    CYAN_BOLD=""

    BOLD=""
    RESET=""
  fi
else
  # Non-color environment
  NORMAL=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
  ORANGE=""

  WHITE_BOLD=""
  MAGENTA_BOLD=""
  CYAN_BOLD=""

  BOLD=""
  RESET=""
fi

# Semantic colors
PRIMARY="${BLUE}"
SECONDARY="${CYAN}"
ACCENT="${ORANGE}"

SUCCESS="${GREEN}"
WARNING="${YELLOW}"
ERROR="${RED}"
INFO="${BLUE}"

CONTENT="${NORMAL}"
HIGHLIGHT="${ACCENT}"
DATA="${WHITE_BOLD}"

HEADER="${YELLOW}"
SUBHEADER="${CYAN_BOLD}"
BULLET="${YELLOW}"
ART="${WHITE_BOLD}"
