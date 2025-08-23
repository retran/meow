#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_LUA_DEVELOPMENT_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_LUA_DEVELOPMENT_ENV_SOURCED=1

if command -v luarocks >/dev/null 2>&1; then
  eval "$(luarocks path --bin)"
fi

export LUA_PATH="./?.lua;./?/init.lua;$HOME/.luarocks/share/lua/5.4/?.lua;$HOME/.luarocks/share/lua/5.4/?/init.lua;;"
export LUA_CPATH="$HOME/.luarocks/lib/lua/5.4/?.so;;"
