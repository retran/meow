#!/usr/bin/env bash

# components/desktop-essential/install.sh - Post-installation setup for desktop-essential

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/system/macos.sh"

if configure_macos; then
  success_tick_msg "macOS configuration complete (may require logout/restart)"
else
  warning "macOS configuration encountered issues or was skipped"
fi
