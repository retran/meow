#!/usr/bin/env bash

# config/env/env.sh - XDG Base Directory specification compliant environment

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_CONFIG_XDG_ENV_SOURCED:-}" ]]; then
  return 0
fi
_CONFIG_XDG_ENV_SOURCED=1

_meow_set_if_command_exists() {
  local var_name="$1"
  shift
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      export "$var_name"="$cmd"
      return 0
    fi
  done
}

export MEOW="${MEOW:-${HOME}/.meow}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

_meow_set_if_command_exists "EDITOR" "nvim" "vim" "nano"
if [[ -n "${EDITOR:-}" ]]; then
  export VISUAL="$EDITOR"
fi

_meow_set_if_command_exists "PAGER" "less" "more"

if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi

export PATH="$HOME/.local/bin:$PATH"

if [[ "$(uname -s)" == "Darwin" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$(go env GOPATH)}"
  export PATH="$GOPATH/bin:$PATH"
fi

if [[ -d "$HOME/.cargo" ]]; then
  source "$HOME/.cargo/env"
fi

export NPM_CONFIG_PREFIX="${HOME}/.npm-global"
if [[ -d "$NPM_CONFIG_PREFIX/bin" ]]; then
  export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
fi

if [[ -f "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh"
fi
