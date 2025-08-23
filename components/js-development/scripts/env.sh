#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_JS_DEVELOPMENT_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_JS_DEVELOPMENT_ENV_SOURCED=1

export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
if [[ -d "$NPM_CONFIG_PREFIX/bin" ]]; then
  export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
fi

export TS_NODE_CACHE_DIRECTORY="${HOME}/.cache/ts-node"
