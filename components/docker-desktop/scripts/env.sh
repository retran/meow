#!/usr/bin/env bash

if [[ -n "${_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED=1

if [[ -f "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh"
fi
