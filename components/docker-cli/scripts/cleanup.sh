#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "docker_cli_cleanup_running")"

if command -v docker >/dev/null 2>&1; then
  ui_info "$(get_static_message "docker_cli_cleaning_cache")"

  docker system prune -f 2>/dev/null || true

  docker builder prune -f 2>/dev/null || true
fi

if [[ -d "$HOME/.docker" ]]; then
  ui_info "$(get_static_message "docker_cli_cleaning_config")"
  rm -f "$HOME/.docker/config.json.backup" 2>/dev/null || true
  rm -rf "$HOME/.docker/cli-plugins/cache" 2>/dev/null || true
fi

if [[ -d "$HOME/.docker/compose" ]]; then
  ui_info "$(get_static_message "docker_cli_cleaning_compose_cache")"
  rm -rf "$HOME/.docker/compose/cache" 2>/dev/null || true
fi

ui_success "$(get_static_message "docker_cli_cleanup_completed")"
