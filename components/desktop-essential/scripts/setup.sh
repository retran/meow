#!/usr/bin/env bash

# components/desktop-essential/install.sh - Post-installation setup for desktop-essential

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/system/macos.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if configure_macos; then
  ui_action_success "$(get_static_message "desktop_essential_macos_config_complete")"
else
  ui_warning "$(get_static_message "desktop_essential_macos_config_issues")"
fi
