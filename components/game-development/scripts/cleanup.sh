#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "game_dev_cleanup_running")"

if pgrep -f "Blender" >/dev/null; then
  ui_info "$(fmt "game_dev_stopping_blender")"
  osascript -e 'tell application "Blender" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "krita" >/dev/null; then
  ui_info "$(fmt "game_dev_stopping_krita")"
  osascript -e 'tell application "krita" to quit' 2>/dev/null || true
  sleep 2
fi

if [[ -d "$HOME/Library/Application Support/Blender" ]]; then
  ui_info "$(fmt "game_dev_cleaning_blender_cache")"
  find "$HOME/Library/Application Support/Blender" -name "*.blend1" -delete 2>/dev/null || true
  find "$HOME/Library/Application Support/Blender" -name "*.blend2" -delete 2>/dev/null || true
  rm -rf "$HOME/Library/Application Support/Blender/*/cache" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Application Support/krita" ]]; then
  ui_info "$(fmt "game_dev_cleaning_krita_cache")"
  rm -rf "$HOME/Library/Application Support/krita/cache" 2>/dev/null || true
  rm -rf "$HOME/Library/Caches/krita" 2>/dev/null || true
  find "$HOME" -name "*.kra~" -delete 2>/dev/null || true
fi

ui_success "$(fmt "game_dev_cleanup_completed")"
