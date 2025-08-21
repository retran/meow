#!/usr/bin/env bash

# components/shell-essential/env.sh - Environment variables for shell-essential

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED=1

# FZF PATH configuration (Homebrew PATH is already set by main config)
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]] && [[ -d "/opt/homebrew/opt/fzf/bin" ]]; then
  export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
