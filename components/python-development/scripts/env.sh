#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_PYTHON_DEVELOPMENT_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_PYTHON_DEVELOPMENT_ENV_SOURCED=1

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export PYTHONIOENCODING=utf-8
export PYTHONDONTWRITEBYTECODE=1
