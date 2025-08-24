#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

ui_action_start "TODO: write message - corporate_configuring"

if [[ -d "/Applications/Slack.app" ]]; then
  ui_info "TODO: write message - corporate_configuring_slack"

  osascript -e '
  tell application "System Events"
      try
          make login item at end with properties {path:"/Applications/Slack.app", hidden:false}
      on error
          -- Login item might already exist
      end try
  end tell
  ' 2>/dev/null || true
fi

if [[ -d "/Applications/zoom.us.app" ]]; then
  ui_info "TODO: write message - corporate_configuring_zoom"

  defaults write us.zoom.xos ZoomEnterMaxWndWhenViewShare -bool true 2>/dev/null || true
  defaults write us.zoom.xos ZoomShouldAutoFitToWindowWhenViewShare -bool true 2>/dev/null || true
fi

ui_action_success "TODO: write message - corporate_configured_successfully"
