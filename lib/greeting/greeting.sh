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
