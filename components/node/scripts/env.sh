#!/usr/bin/env bash

if [ -n "${_COMPONENT_NODE_ENV_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_NODE_ENV_SOURCED=1

export NPM_CONFIG_PREFIX="${HOME}/.npm-global"

if [ -d "$NPM_CONFIG_PREFIX/bin" ]; then
  export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
fi
