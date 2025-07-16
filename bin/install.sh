#!/usr/bin/env bash

# bin/install.sh - Script to install dotfiles

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.meow}"

# If running from the repo directory (development mode), use current directory
if [[ -f "./config/env/env.sh" && -d "./presets" ]]; then
  DOTFILES_DIR="$(pwd)"
fi

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
  msg 0 "  PRESET            Apply a specific preset"
  msg 0 ""
  msg 0 "Available presets:"
  msg 0 "  personal          Complete development setup with all packages"
  msg 0 "  corporate         Work-focused Go development environment"
  msg 0 "  shell-essential   Minimal setup for servers (Git, Tmux, Starship, Neovim)"
  msg 0 "  desktop-essential GUI foundation without specific dev tools"
  msg 0 "  javascript        JavaScript/TypeScript development environment"
  msg 0 "  react             React development extending JavaScript preset"
  msg 0 "  web               Complete web development with CSS, build tools, deployment"
  msg 0 "  markdown          Markdown writing and documentation tools"
  msg 0 ""
  msg 0 "Options:"
  msg 0 "  --help            Show this help message"
  msg 0 ""
  msg 0 "Examples:"
  msg 0 "  $0 personal"
  msg 0 "  $0 javascript"
  msg 0 "  $0 react"
  msg 0 "  $0 markdown"
  msg 0 ""
}

parse_arguments() {
  local preset_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help | -h)
        # This should not be reached due to pre-check in main
        exit 0
        ;;
      --*)
        error 0 "Unknown option: $1" >&2
        show_help >&2
        exit 1
        ;;
      *)
        if [[ -n "$preset_name" ]]; then
          error 0 "Multiple preset names provided. Please specify only one." >&2
          show_help >&2
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
  # Check for help first before parsing
  for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
      show_help
      exit 0
    fi
  done

  local preset_name
  preset_name=$(parse_arguments "$@")

  validate_preset_argument "$preset_name"
  install_preset "$preset_name"
}

main "$@"
