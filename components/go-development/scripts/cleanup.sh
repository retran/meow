#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "go_dev_cleanup_running")"

if command -v go >/dev/null 2>&1; then
  ui_info "$(fmt "go_dev_cleaning_module_cache")"
  go clean -modcache 2>/dev/null || true

  ui_info "$(fmt "go_dev_cleaning_build_cache")"
  go clean -cache 2>/dev/null || true

  ui_info "$(fmt "go_dev_cleaning_test_cache")"
  go clean -testcache 2>/dev/null || true
fi

if [[ -f "$HOME/go.work" ]]; then
  ui_info "$(fmt "go_dev_removing_workspace")"
  rm -f "$HOME/go.work" || true
fi

if [[ -n "${GOPATH:-}" && -d "$GOPATH/pkg" ]]; then
  ui_info "$(fmt "go_dev_cleaning_gopath_pkg")"
  rm -rf "$GOPATH/pkg" 2>/dev/null || true
fi

ui_success "$(fmt "go_dev_cleanup_completed")"
