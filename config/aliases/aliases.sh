#!/usr/bin/env bash

# config/aliases/aliases.sh - Shell aliases configuration

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_CONFIG_ALIASES_SOURCED:-}" ]]; then
  return 0
fi
_CONFIG_ALIASES_SOURCED=1


if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l'
  alias la='eza -la'
  alias tree='eza --tree'
fi
