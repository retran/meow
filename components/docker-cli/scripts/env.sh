#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_DOCKER_CLI_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_DOCKER_CLI_ENV_SOURCED=1

if [[ -z "${DOCKER_HOST:-}" ]]; then
  if [[ -S "/var/run/docker.sock" ]]; then
    export DOCKER_HOST="unix:///var/run/docker.sock"
  elif [[ -S "/run/docker.sock" ]]; then
    export DOCKER_HOST="unix:///run/docker.sock"
  elif [[ -S "$HOME/.docker/run/docker.sock" ]]; then
    export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
  fi
fi

if command -v docker >/dev/null 2>&1; then
  if docker context ls --format "{{.Name}}" 2>/dev/null | grep -q "^host$"; then
    export DOCKER_CONTEXT="host"
  fi
fi

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
