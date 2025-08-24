#!/usr/bin/env bash

# JavaScript Development component cleanup script
# This script is executed when the js-development component is being uninstalled

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "js_dev_cleanup_running")"

if command -v npm >/dev/null 2>&1; then
  ui_info "$(fmt "js_dev_cleaning_npm_cache")"
  npm cache clean --force 2>/dev/null || true
fi

if [[ -d "$HOME/.tscache" ]]; then
  ui_info "$(fmt "js_dev_removing_ts_cache")"
  rm -rf "$HOME/.tscache" || true
fi

if [[ -d "$HOME/.npm-global" ]]; then
  ui_info "$(fmt "js_dev_cleaning_global_npm")"
  rm -rf "$HOME/.npm-global/lib/node_modules/.cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.eslintcache" ]]; then
  ui_info "$(fmt "js_dev_removing_eslint_cache")"
  rm -rf "$HOME/.eslintcache" || true
fi

ui_success "$(fmt "js_dev_cleanup_completed")"
