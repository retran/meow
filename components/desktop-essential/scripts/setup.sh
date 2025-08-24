#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/system/macos.sh"
source "${MEOW}/lib/core/ui.sh"

if configure_macos; then
  ui_action_success "macOS configuration complete (may require logout/restart)"
else
  ui_warning "macOS configuration encountered issues or was skipped"
fi
