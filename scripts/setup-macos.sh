#!/usr/bin/env bash

# scripts/setup-macos.sh - Script to configure macOS settings

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/system/macos.sh"

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Configuring macOS for preset: $PRESET"

  if configure_macos "$indent_level"; then
    success_tick_msg "$indent_level" "macOS configuration complete. (May require logout/restart)"
  else
    indented_warning "$indent_level" "macOS configuration encountered issues or was skipped."
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
