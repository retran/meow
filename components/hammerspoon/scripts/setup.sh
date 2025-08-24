#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if [[ "$OSTYPE" != "darwin"* ]]; then
  ui_warning "$(fmt "hammerspoon_macos_only")"
  exit 0
fi

if ! command -v hs >/dev/null 2>&1 && ! [[ -d "/Applications/Hammerspoon.app" ]]; then
  ui_warning "$(fmt "hammerspoon_not_installed")"
  exit 0
fi

ui_action_start "$(fmt "hammerspoon_configuring")"

if ! pgrep -x "Hammerspoon" >/dev/null; then
  ui_info "$(fmt "hammerspoon_starting")"
  open -a Hammerspoon 2>/dev/null || true
  sleep 2
fi

ui_info "$(fmt "hammerspoon_adding_login_items")"
osascript -e '
tell application "System Events"
    try
        make login item at end with properties {path:"/Applications/Hammerspoon.app", hidden:false}
    on error
        -- Login item might already exist
    end try
end tell
' 2>/dev/null || true

ui_info "$(fmt "hammerspoon_accessibility_permissions")"

ui_action_success "$(fmt "hammerspoon_configured_successfully")"
