#!/usr/bin/env bash

# scripts/setup-shell-essential.sh - Script to set up essential shell environment

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/system/rust.sh"

main() {
  local indent_level="$INDENT_LEVEL"

  step_header "$indent_level" "Setting up Rust development environment for preset: $PRESET"

  setup_rustup "$((indent_level + 1))" || true

  success_tick_msg "$indent_level" "Rust development environment setup complete"
}

main "$@"
