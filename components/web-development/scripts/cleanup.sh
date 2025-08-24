#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "TODO: write message - web_dev_cleanup_running"

if [[ -d "$HOME/.sass-cache" ]]; then
  ui_info "TODO: write message - web_dev_cleaning_sass_cache"
  rm -rf "$HOME/.sass-cache" 2>/dev/null || true
fi

ui_info "TODO: write message - web_dev_cleaning_tailwind_cache"
find "$HOME" -name ".tailwindcss-cache" -type d -exec rm -rf {} + 2>/dev/null || true

if [[ -d "$HOME/.config/lighthouse" ]]; then
  ui_info "TODO: write message - web_dev_cleaning_lighthouse_cache"
  rm -rf "$HOME/.config/lighthouse/cache" 2>/dev/null || true
  rm -f "$HOME/lighthouse-report*.html" 2>/dev/null || true
fi

if [[ -d "$HOME/.netlify" ]]; then
  ui_info "TODO: write message - web_dev_cleaning_netlify_cache"
  rm -rf "$HOME/.netlify/cache" 2>/dev/null || true
fi

ui_success "TODO: write message - web_dev_cleanup_completed"
