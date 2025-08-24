#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

ui_action_start "$(fmt "fonts_configuring")"

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "$(fmt "fonts_refreshing_cache")"

  sudo atsutil databases -remove 2>/dev/null || true
  atsutil server -shutdown 2>/dev/null || true
  atsutil server -ping 2>/dev/null || true

  killall Finder 2>/dev/null || true
fi

ui_info "$(fmt "fonts_verifying_installation")"

if fc-list 2>/dev/null | grep -qi "jetbrains" || system_profiler SPFontsDataType 2>/dev/null | grep -qi "jetbrains"; then
  ui_info "$(fmt "fonts_jetbrains_mono_detected")"
else
  ui_warning "$(fmt "fonts_jetbrains_mono_not_detected")"
fi

if fc-list 2>/dev/null | grep -qi "fira" || system_profiler SPFontsDataType 2>/dev/null | grep -qi "fira"; then
  ui_info "$(fmt "fonts_fira_sans_detected")"
else
  ui_warning "$(fmt "fonts_fira_sans_not_detected")"
fi

ui_action_success "$(fmt "fonts_configured_successfully")"
