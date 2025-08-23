#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "meowvim_keyboard_cleanup_running")"

ui_info "$(get_static_message "meowvim_keyboard_cleaning_cache")"
rm -rf "$HOME/.local/share/nvim/keyboard-layouts" 2>/dev/null || true
rm -f "/tmp/nvim_keyboard_*" 2>/dev/null || true

ui_success "$(get_static_message "meowvim_keyboard_cleanup_completed")"
