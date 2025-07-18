#!/usr/bin/env bash

# bin/update.sh - Script to update dotfiles

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.meow}"

if [[ -f "./config/env/env.sh" && -d "./presets" ]]; then
  DOTFILES_DIR="$(pwd)"
fi

source "${DOTFILES_DIR}/config/env/env.sh"
source "${DOTFILES_DIR}/lib/core/bash_compat.sh"
source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/commands/update.sh"

show_help() {
    title 0 "meow Update"
    msg 0 "Updates packages for installed presets or a specific preset."
    msg 0 ""
    show_bash_version_info 0
    msg 0 ""
    msg 0 "Usage: $0 [PRESET]"
    msg 0 ""
    msg 0 "Arguments:"
    msg 0 "  PRESET            Update packages for a specific preset (optional)"
    msg 0 ""
    msg 0 "Options:"
    msg 0 "  --help            Show this help message"
    msg 0 ""
    msg 0 "Examples:"
    msg 0 "  $0"
    msg 0 "  $0 personal"
    msg 0 "  $0 corporate"
    msg 0 ""
}

parse_arguments() {
    local preset_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help | -h)
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

main() {
    # Check bash compatibility early
    warn_bash_compatibility 0
    
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            show_help
            exit 0
        fi
    done

    local preset_name
    preset_name=$(parse_arguments "$@")

    set +e
    if [[ -n "$preset_name" ]]; then
        update_preset "$preset_name"
        local exit_code=$?
    else
        update_installed_presets
        local exit_code=$?
    fi
    set -e

    exit $exit_code
}

main "$@"
