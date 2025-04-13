#!/usr/bin/env bash

# bin/update.sh - Script to update dotfiles

set -euo pipefail

DOTFILES_DIR="$HOME/.meow"

source "${DOTFILES_DIR}/config/env/env.sh"
source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/commands/update.sh"

show_help() {
    title 0 "meow Update"
    msg 0 "Updates packages for installed presets or a specific preset."
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
    msg 0 "  $0 core-shell"
    msg 0 "  $0 core-desktop"
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

main() {
    local preset_name
    preset_name=$(parse_arguments "$@")

    if [[ -n "$preset_name" ]]; then
        update_preset "$preset_name"
    else
        update_installed_presets
    fi
}

main "$@"
