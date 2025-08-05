#!/usr/bin/env bash

# scripts/setup-node-config.sh - Script to configure the Node.js environment for global packages

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"

main() {
  local indent_level="$INDENT_LEVEL"
  local child_indent=$((indent_level + 1))

  step_header "$indent_level" "Running Setup Script for 'node-config'"

  if ! command -v npm >/dev/null 2>&1; then
    indented_warning "$child_indent" "npm command not found. Skipping Node.js configuration."
    return 0
  fi

  action_msg "$child_indent" "Configuring npm for global packages without sudo..."
  
  local npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

  mkdir -p "$npm_global_path"
  npm config set prefix "$npm_global_path"
  
  success_tick_msg "$child_indent" "NPM configured successfully."
  success_tick_msg "$indent_level" "Node.js environment configuration complete"
}

main "$@"
