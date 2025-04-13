#!/usr/bin/env bash

# bin/install.sh - Script to install dotfiles

set -euo pipefail

DOTFILES_DIR="$HOME/.meow"

source "${DOTFILES_DIR}/config/env/env.sh"
source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/commands/install.sh"

show_help() {
  title 0 "dotfiles Install"
  msg 0 "Installs your system with your preferred configuration."
  msg 0 ""
  msg 0 "Usage: $0 PRESET"
  msg 0 ""
  msg 0 "Arguments:"
  msg 0 "  PRESET            Apply a specific preset (core-shell, core-desktop, all)"
  msg 0 ""
  msg 0 "Options:"
  msg 0 "  --help            Show this help message"
  msg 0 ""
  msg 0 "Examples:"
  msg 0 "  $0 core-shell"
  msg 0 "  $0 core-desktop"
  msg 0 "  $0 all"
  msg 0 ""
}

parse_arguments() {
  local preset_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help | -h)
        show_help
        exit 0
        ;;
      --*)
        error 0 "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        if [[ -n "$preset_name" ]]; then
          error 0 "Multiple preset names provided. Please specify only one."
          show_help
          exit 1
        fi
        preset_name="$1"
        ;;
    esac
    shift
  done

  echo "$preset_name"
}

validate_preset_argument() {
  local preset_name="$1"

  if [[ -z "$preset_name" ]]; then
    error 0 "No preset specified. Please provide a preset name."
    show_help
    exit 1
  fi
}

main() {
  local preset_name
  preset_name=$(parse_arguments "$@")

  validate_preset_argument "$preset_name"
  install_preset "$preset_name"
}

main "$@"
