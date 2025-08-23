#!/usr/bin/env bash

# Docker Desktop component cleanup script
# This script is executed when the docker-desktop component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "docker_cleanup_running")"

# Stop Docker Desktop if it's running
if pgrep -f "Docker Desktop" >/dev/null; then
  ui_info "$(get_static_message "docker_stopping_desktop")"
  osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null || true
  sleep 3
fi

# Stop Docker daemon if it's running
if pgrep -f "dockerd" >/dev/null; then
  ui_info "$(get_static_message "docker_stopping_daemon")"
  pkill -f "dockerd" 2>/dev/null || true
  sleep 2
fi

# Clean up Docker networks and volumes
if command -v docker >/dev/null 2>&1; then
  ui_info "$(get_static_message "docker_cleaning_networks_volumes")"
  docker system prune -af --volumes 2>/dev/null || true
fi

# Remove Docker Desktop from login items (macOS specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
  ui_info "$(get_static_message "docker_removing_login_items")"
  osascript -e 'tell application "System Events" to delete login item "Docker Desktop"' 2>/dev/null || true
fi

ui_success "$(get_static_message "docker_cleanup_completed")"
ui_info "$(get_static_message "docker_images_containers_cleaned")"
ui_info "$(get_static_message "docker_manual_removal_note")"
