#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_PYTHON_DEVELOPMENT_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_PYTHON_DEVELOPMENT_INIT_SOURCED=1

if command -v pyenv &>/dev/null; then
  eval "$(pyenv init -)"
fi
