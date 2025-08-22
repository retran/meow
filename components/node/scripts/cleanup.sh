#!/usr/bin/env bash

# Node component cleanup script
# This script is executed when the node component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "node_cleanup_running")"

# Clean npm cache
if command -v npm >/dev/null 2>&1; then
  echo "$(get_static_message "node_cleaning_npm_cache")"
  npm cache clean --force 2>/dev/null || true
fi

# Clean yarn cache if yarn is installed
if command -v yarn >/dev/null 2>&1; then
  echo "$(get_static_message "node_cleaning_yarn_cache")"
  yarn cache clean 2>/dev/null || true
fi

# Clean pnpm cache if pnpm is installed
if command -v pnpm >/dev/null 2>&1; then
  echo "$(get_static_message "node_cleaning_pnpm_cache")"
  pnpm store prune 2>/dev/null || true
fi

# Clean npm global cache
if [[ -d "$HOME/.npm" ]]; then
  echo "$(get_static_message "node_cleaning_global_npm_cache")"
  rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
fi

# Clean node-gyp cache
if [[ -d "$HOME/.node-gyp" ]]; then
  echo "$(get_static_message "node_cleaning_node_gyp_cache")"
  rm -rf "$HOME/.node-gyp" 2>/dev/null || true
fi

echo "$(get_static_message "node_cleanup_completed")"
