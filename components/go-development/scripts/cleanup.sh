#!/usr/bin/env bash

# Go Development component cleanup script
# This script is executed when the go-development component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "go_dev_cleanup_running")"

# Clear Go module cache
if command -v go >/dev/null 2>&1; then
  echo "$(get_static_message "go_dev_cleaning_module_cache")"
  go clean -modcache 2>/dev/null || true

  echo "$(get_static_message "go_dev_cleaning_build_cache")"
  go clean -cache 2>/dev/null || true

  echo "$(get_static_message "go_dev_cleaning_test_cache")"
  go clean -testcache 2>/dev/null || true
fi

# Remove Go workspace configuration if exists
if [[ -f "$HOME/go.work" ]]; then
  echo "$(get_static_message "go_dev_removing_workspace")"
  rm -f "$HOME/go.work" || true
fi

# Clean up any leftover build artifacts in GOPATH
if [[ -n "${GOPATH:-}" && -d "$GOPATH/pkg" ]]; then
  echo "$(get_static_message "go_dev_cleaning_gopath_pkg")"
  rm -rf "$GOPATH/pkg" 2>/dev/null || true
fi

echo "$(get_static_message "go_dev_cleanup_completed")"
