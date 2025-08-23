#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "desktop_essential_cleanup_running")"

if [[ -d "$HOME/Library/Caches/Google/Chrome" ]]; then
  ui_info "$(get_static_message "desktop_essential_cleaning_chrome_cache")"
  rm -rf "$HOME/Library/Caches/Google/Chrome/Default/Cache" 2>/dev/null || true
  rm -rf "$HOME/Library/Caches/Google/Chrome/Default/Media Cache" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/com.microsoft.VSCode" ]]; then
  ui_info "$(get_static_message "desktop_essential_cleaning_vscode_cache")"
  rm -rf "$HOME/Library/Caches/com.microsoft.VSCode/logs" 2>/dev/null || true
  rm -rf "$HOME/Library/Caches/com.microsoft.VSCode/CachedExtensions" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/com.raycast.macos" ]]; then
  ui_info "$(get_static_message "desktop_essential_cleaning_raycast_cache")"
  rm -rf "$HOME/Library/Caches/com.raycast.macos" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/Alacritty" ]]; then
  ui_info "$(get_static_message "desktop_essential_cleaning_alacritty_logs")"
  rm -rf "$HOME/Library/Logs/Alacritty" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/com.bitwarden.desktop" ]]; then
  ui_info "$(get_static_message "desktop_essential_cleaning_bitwarden_cache")"
  rm -rf "$HOME/Library/Caches/com.bitwarden.desktop" 2>/dev/null || true
fi

ui_success "$(get_static_message "desktop_essential_cleanup_completed")"
