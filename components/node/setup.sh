#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if ! command -v npm >/dev/null 2>&1; then
  warning "npm command not found. Skipping Node.js configuration"
  return 0
fi

action_msg "Configuring npm for global packages without sudo"

npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

mkdir -p "$npm_global_path"
npm config set prefix "$npm_global_path"

success_tick_msg "NPM configured successfully"
