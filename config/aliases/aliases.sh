#!/usr/bin/env bash

# config/aliases/aliases.sh - Shell aliases configuration

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_CONFIG_ALIASES_SOURCED:-}" ]]; then
  return 0
fi
_CONFIG_ALIASES_SOURCED=1

# aliases
alias vim='nvim'
alias vi='nvim'
