#!/usr/bin/env bash

# lib/core/colors.sh - Color definitions for terminal output

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_COLORS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_COLORS_SOURCED=1

if [ -t 1 ]; then
  # Tokyo Night color palette using tput with RGB values
  # Check if terminal supports RGB colors
  if [[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]]; then
    # Use RGB colors for better Tokyo Night accuracy
    NORMAL="\033[38;2;192;202;245m"      # #c0caf5 - Tokyo Night foreground
    RED="\033[38;2;247;118;142m"         # #f7768e - Tokyo Night red
    GREEN="\033[38;2;158;206;106m"       # #9ece6a - Tokyo Night green
    YELLOW="\033[38;2;224;175;104m"      # #e0af68 - Tokyo Night yellow
    BLUE="\033[38;2;122;162;247m"        # #7aa2f7 - Tokyo Night blue
    MAGENTA="\033[38;2;187;154;247m"     # #bb9af7 - Tokyo Night purple
    CYAN="\033[38;2;125;207;255m"        # #7dcfff - Tokyo Night cyan
    ORANGE="\033[38;2;255;158;100m"      # #ff9e64 - Tokyo Night orange
  else
    # Fallback to 256-color approximations for Tokyo Night
    NORMAL="$(tput setaf 254)"    # Light gray
    RED="$(tput setaf 210)"       # Light pink/red
    GREEN="$(tput setaf 150)"     # Light green
    YELLOW="$(tput setaf 222)"    # Light yellow
    BLUE="$(tput setaf 111)"      # Light blue
    MAGENTA="$(tput setaf 183)"   # Light purple
    CYAN="$(tput setaf 117)"      # Light cyan
    ORANGE="$(tput setaf 215)"    # Orange
  fi

  WHITE_BOLD="$(tput bold)${NORMAL}"
  MAGENTA_BOLD="$(tput bold)${MAGENTA}"
  CYAN_BOLD="$(tput bold)${CYAN}"

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

  BOLD="$(tput bold)"
  RESET="$(tput sgr0)"
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
