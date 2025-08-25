#!/usr/bin/env bash

if [ -n "${_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED=1

path_contains_fzf_bin=0
case "$PATH" in
  */opt/homebrew/opt/fzf/bin*)
    path_contains_fzf_bin=1
    ;;
esac

if [ "$path_contains_fzf_bin" -eq 0 ] && [ -d "/opt/homebrew/opt/fzf/bin" ]; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: Adding /opt/homebrew/opt/fzf/bin to PATH" >&2
  fi
  if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
    export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
  else
    echo "DRY-RUN: Would add /opt/homebrew/opt/fzf/bin to PATH" >&2
  fi
fi
