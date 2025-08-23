#!/usr/bin/env bash

# Node component cleanup script
# This script is executed when the node component is being uninstalled

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "node_cleanup_running")"

if command -v npm >/dev/null 2>&1; then
  ui_info "$(get_static_message "node_cleaning_npm_cache")"
  npm cache clean --force 2>/dev/null || true
fi

if command -v yarn >/dev/null 2>&1; then
  ui_info "$(get_static_message "node_cleaning_yarn_cache")"
  yarn cache clean 2>/dev/null || true
fi

if command -v pnpm >/dev/null 2>&1; then
  ui_info "$(get_static_message "node_cleaning_pnpm_cache")"
  pnpm store prune 2>/dev/null || true
fi

if [[ -d "$HOME/.npm" ]]; then
  ui_info "$(get_static_message "node_cleaning_global_npm_cache")"
  rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
fi

if [[ -d "$HOME/.node-gyp" ]]; then
  ui_info "$(get_static_message "node_cleaning_node_gyp_cache")"
  rm -rf "$HOME/.node-gyp" 2>/dev/null || true
fi

ui_success "$(get_static_message "node_cleanup_completed")"
