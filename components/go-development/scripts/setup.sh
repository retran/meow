#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if ! command -v go >/dev/null 2>&1; then
  ui_warning "TODO: write message - go_dev_go_not_found_skip"
  exit 0
fi

ui_action_start "TODO: write message - go_dev_configuring"

if [[ -z "${GOPATH:-}" ]]; then
  ui_info "TODO: write message - go_dev_setting_gopath"
  GOPATH=$(go env GOPATH)
  mkdir -p "$GOPATH/bin" 2>/dev/null || true
fi

ui_action_success "TODO: write message - go_dev_configuration_completed"
