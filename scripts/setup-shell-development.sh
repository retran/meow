#!/usr/bin/env bash

# scripts/setup-shell-development.sh - Script to set up shell development environment

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up shell development environment for preset: $PRESET"

  info "$indent_level" "Shell development tools installed via package manager"
  info "$indent_level" "Available tools: shellcheck, shfmt, bash-language-server, go-task, pandoc"

  success_tick_msg "$indent_level" "Shell development environment setup complete"
}

main "$@"