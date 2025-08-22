#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if ! command -v npm >/dev/null 2>&1; then
  ui_warning "$(get_static_message "node_npm_not_found_skip")"
  return 0
fi

ui_action_start "$(get_static_message "node_configuring_global_packages")"

npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

mkdir -p "$npm_global_path"
npm config set prefix "$npm_global_path"

ui_action_success "$(get_static_message "node_npm_configured_successfully")"
