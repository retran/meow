#!/usr/bin/env bash

# Enable strict mode: exit on error, treat unset variables as an error,
# and propagate exit codes through pipelines.

# This block ensures the script's functions are defined only once if sourced
# multiple times, and makes it safe to run directly.
if [ -n "${_LIB_CORE_COLORS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_COLORS_SOURCED=1

# Check if the output is directed to a terminal to enable colors.
if [ -t 1 ]; then
  # Attempt to use 24-bit truecolor codes if COLORTERM indicates support.
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
    # Fallback to 256-color palette using tput for broader compatibility.
    NORMAL="$(tput setaf 254)"
    RED="$(tput setaf 210)"
    GREEN="$(tput setaf 150)"
    YELLOW="$(tput setaf 222)"
    BLUE="$(tput setaf 111)"
    MAGENTA="$(tput setaf 183)"
    CYAN="$(tput setaf 117)"
    ORANGE="$(tput setaf 215)"
  fi

  # Define bold variants for some colors using tput.
  WHITE_BOLD="$(tput bold)${NORMAL}"
  MAGENTA_BOLD="$(tput bold)${MAGENTA}"
  CYAN_BOLD="$(tput bold)${CYAN}"

  # Define semantic color variables based on the chosen palette.
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

  # General text styling.
  BOLD="$(tput bold)"
  RESET="$(tput sgr0)"
else
  # If not a terminal, define all color variables as empty strings.
  # This prevents color codes from appearing in redirected output.
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
