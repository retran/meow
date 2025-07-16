#!/usr/bin/env bash

# lib/greeting/greeting.sh - Functions for displaying a greeting message in the terminal

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_GREETING_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_GREETING_SOURCED=1

ASSETS_DIR="${DOTFILES_DIR}/assets"

source "${DOTFILES_DIR}/lib/core/colors.sh"
source "${DOTFILES_DIR}/lib/greeting/fetch.sh"
source "${DOTFILES_DIR}/lib/greeting/art.sh"
source "${DOTFILES_DIR}/lib/greeting/comments.sh"
source "${DOTFILES_DIR}/lib/greeting/build.sh"
source "${DOTFILES_DIR}/lib/greeting/display.sh"

CACHE_DIR="${HOME}/.cache/shell-greeting"
mkdir -p "${CACHE_DIR}"

ASCII_ART_FILE="${ASSETS_DIR}/ascii/greeting.ascii"
commentary_lines=()
art=()

show_greeting() {
  # Clear global arrays to prevent duplication
  commentary_lines=()
  art=()
  
  load_art
  get_system_info
  build_system_stats
  display_art_and_stats
}

# Example of using the more functional approach (reduced global dependencies)
show_greeting_functional_demo() {
  # Load system info without setting global variables
  local system_info
  system_info=$(get_system_info_structured)
  
  # Parse system info into local variables
  local date_full time_current os_info uptime_info home_disk_space ram_stats outdated_packages hour_num
  while IFS='=' read -r key value; do
    case "$key" in
      DATE_FULL) date_full="$value" ;;
      TIME_CURRENT) time_current="$value" ;;
      OS_INFO) os_info="$value" ;;
      UPTIME_INFO) uptime_info="$value" ;;
      HOME_DISK_SPACE) home_disk_space="$value" ;;
      RAM_STATS) ram_stats="$value" ;;
      OUTDATED_PACKAGES) outdated_packages="$value" ;;
      HOUR_NUM) hour_num="$value" ;;
    esac
  done <<< "$system_info"
  
  # Load art and comments functionally
  local demo_art=()
  local demo_commentary=()
  
  init_comment_collections
  load_art_functional "$ASCII_ART_FILE" demo_art
  build_greeting_functional "$hour_num" "$date_full" "$time_current" demo_commentary
  
  echo "Functional demo - Date: $date_full, Time: $time_current"
  echo "Art lines: ${#demo_art[@]}, Commentary lines: ${#demo_commentary[@]}"
  echo "First art line: ${demo_art[0]}"
  echo "First commentary: ${demo_commentary[0]}"
}
