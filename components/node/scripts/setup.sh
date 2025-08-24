#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if ! command -v npm >/dev/null 2>&1; then
  ui_warning "npm command not found. Skipping Node.js configuration"
  return 0
fi

ui_action_start "Configuring npm for global packages without sudo"

npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

mkdir -p "$npm_global_path"
npm config set prefix "$npm_global_path"

ui_action_success "NPM configured successfully"
