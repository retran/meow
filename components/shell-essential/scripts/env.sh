#!/usr/bin/env bash

if [[ -n "${_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED=1

if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]] && [[ -d "/opt/homebrew/opt/fzf/bin" ]]; then
  export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
