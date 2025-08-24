#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "pipx_cleanup_running")"

if command -v pipx >/dev/null 2>&1; then
  ui_info "$(fmt "pipx_cleaning_cache")"
  pipx uninstall-all --force 2>/dev/null || true
fi

if [[ -d "$HOME/.local/share/pipx" ]]; then
  ui_info "$(fmt "pipx_cleaning_installation_dir")"
  rm -rf "$HOME/.local/share/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.cache/pipx" ]]; then
  ui_info "$(fmt "pipx_cleaning_cache_dir")"
  rm -rf "$HOME/.cache/pipx" 2>/dev/null || true
fi

if [[ -d "$HOME/.local/bin" ]]; then
  ui_info "$(fmt "pipx_cleaning_binaries")"
  find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; 2>/dev/null || true
fi

ui_success "$(fmt "pipx_cleanup_completed")"
