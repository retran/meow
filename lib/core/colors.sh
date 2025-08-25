#!/usr/bin/env bash

if [ -n "${_LIB_CORE_COLORS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_COLORS_SOURCED=1

# Check if stdout is a terminal
if [ -t 1 ]; then
  # Determine color support
  if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
    NORMAL="\033[38;2;192;202;245m"
    RED="\033[38;2;247;118;142m"
    GREEN="\033[38;2;158;206;106m"
    YELLOW="\033[38;2;224;175;104m"
    BLUE="\033[38;2;122;162;247m"
    MAGENTA="\033[38;2;187;154;247m"
    CYAN="\033[38;2;125;207;255m"
    ORANGE="\033[38;2;255;158;100m"
  else
    NORMAL="$(tput setaf 254)"
    RED="$(tput setaf 210)"
    GREEN="$(tput setaf 150)"
    YELLOW="$(tput setaf 222)"
    BLUE="$(tput setaf 111)"
    MAGENTA="$(tput setaf 183)"
    CYAN="$(tput setaf 117)"
    ORANGE="$(tput setaf 215)"
  fi

  # Bold variants
  WHITE_BOLD="$(tput bold)${NORMAL}"
  MAGENTA_BOLD="$(tput bold)${MAGENTA}"
  CYAN_BOLD="$(tput bold)${CYAN}"

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

  # Formatting
  BOLD="$(tput bold)"
  RESET="$(tput sgr0)"
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

  PRIMARY=""
  SECONDARY=""
  ACCENT=""

  SUCCESS=""
  WARNING=""
  ERROR=""
  INFO=""

  CONTENT=""
  HIGHLIGHT=""
  DATA=""

  HEADER=""
  SUBHEADER=""
  BULLET=""
  ART=""

  BOLD=""
  RESET=""
fi
