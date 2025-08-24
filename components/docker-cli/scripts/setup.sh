#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "docker_cli_setup_running")"

if ! command -v docker >/dev/null 2>&1; then
  ui_warning "Docker CLI not found. Installation may not be complete."
  exit 1
fi

ui_info "$(fmt "docker_cli_checking_host_socket")"

DOCKER_SOCKETS=(
  "/var/run/docker.sock"
  "/run/docker.sock"
  "$HOME/.docker/run/docker.sock"
)

DOCKER_HOST_FOUND=""
for socket in "${DOCKER_SOCKETS[@]}"; do
  if [[ -S "$socket" ]]; then
    DOCKER_HOST_FOUND="$socket"
    break
  fi
done

if [[ -z "$DOCKER_HOST_FOUND" ]]; then
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    ui_info "  Using DOCKER_HOST environment variable: $DOCKER_HOST"
  else
    ui_warning "No Docker socket found. Make sure Docker socket is mounted or DOCKER_HOST is set."
    ui_info "  For containers, mount: -v /var/run/docker.sock:/var/run/docker.sock"
    exit 1
  fi
else
  ui_info "  Found Docker socket: $DOCKER_HOST_FOUND"
fi

ui_info "$(fmt "docker_cli_configuring_context")"

if [[ -n "$DOCKER_HOST_FOUND" ]]; then
  docker context create host --docker "host=unix://$DOCKER_HOST_FOUND" 2>/dev/null || \
  docker context update host --docker "host=unix://$DOCKER_HOST_FOUND" 2>/dev/null || true
  docker context use host 2>/dev/null || true
fi

ui_info "$(fmt "docker_cli_testing_connection")"

if docker version >/dev/null 2>&1; then
  ui_success "$(fmt "docker_cli_setup_completed")"
  ui_info "$(fmt "docker_cli_ready_to_use")"
else
  ui_warning "Docker connection test failed. Please check:"
  ui_info "  1. Docker daemon is running on host"
  ui_info "  2. Docker socket is properly mounted in container"
  ui_info "  3. Current user has permission to access Docker socket"
  exit 1
fi
