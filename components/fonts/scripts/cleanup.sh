#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "TODO: write message - fonts_cleanup_running"

if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "TODO: write message - fonts_clearing_cache"

  sudo atsutil databases -remove 2>/dev/null || true
  atsutil server -shutdown 2>/dev/null || true
  atsutil server -ping 2>/dev/null || true
fi

if command -v fc-cache >/dev/null 2>&1; then
  ui_info "TODO: write message - fonts_clearing_fontconfig_cache"
  fc-cache -f 2>/dev/null || true
fi

ui_success "TODO: write message - fonts_cleanup_completed"
