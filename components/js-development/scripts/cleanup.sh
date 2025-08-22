#!/usr/bin/env bash

# JavaScript Development component cleanup script
# This script is executed when the js-development component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "js_dev_cleanup_running")"

# Clear npm cache
if command -v npm >/dev/null 2>&1; then
  echo "$(get_static_message "js_dev_cleaning_npm_cache")"
  npm cache clean --force 2>/dev/null || true
fi

# Remove TypeScript compiler cache
if [[ -d "$HOME/.tscache" ]]; then
  echo "$(get_static_message "js_dev_removing_ts_cache")"
  rm -rf "$HOME/.tscache" || true
fi

# Clean up node_modules global symlinks (if any were created)
if [[ -d "$HOME/.npm-global" ]]; then
  echo "$(get_static_message "js_dev_cleaning_global_npm")"
  rm -rf "$HOME/.npm-global/lib/node_modules/.cache" 2>/dev/null || true
fi

# Clear eslint cache
if [[ -d "$HOME/.eslintcache" ]]; then
  echo "$(get_static_message "js_dev_removing_eslint_cache")"
  rm -rf "$HOME/.eslintcache" || true
fi

echo "$(get_static_message "js_dev_cleanup_completed")"
