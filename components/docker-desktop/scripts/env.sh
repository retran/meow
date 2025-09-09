#!/usr/bin/env bash
# @file:    components/docker-desktop/scripts/env.sh
# @brief:   Installation or configuration script for docker-desktop component.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_DOCKER_DESKTOP_ENV_SOURCED=1

if [ -f "$HOME/.orbstack/shell/init.zsh" ]; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    printf "INFO: Sourcing OrbStack init file: %s\n" "$HOME/.orbstack/shell/init.zsh"
  fi

  if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
    source "$HOME/.orbstack/shell/init.zsh"
  else
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      printf "DRY-RUN: Would source OrbStack init file: %s\n" "$HOME/.orbstack/shell/init.zsh"
    fi
  fi
fi
