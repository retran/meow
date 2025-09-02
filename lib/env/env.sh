#!/usr/bin/env bash

if [ -n "${_MEOW_CORE_ENV_SOURCED:-}" ]; then
  return 0
fi
_MEOW_CORE_ENV_SOURCED=1

_meow_set_if_command_exists() {
  local var_name="$1"
  shift
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      export "$var_name"="$cmd"
      return 0
    fi
  done
  return 1
}

export MEOW="${MEOW:-${HOME}/.meow}"

if [ -f "./config/env/env.sh" ] && [ -d "./presets" ]; then
  MEOW="$(pwd)"
  export MEOW
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

_meow_set_if_command_exists "EDITOR" "nvim" "vim" "nano"
if [ -n "${EDITOR:-}" ]; then
  export VISUAL="$EDITOR"
fi

_meow_set_if_command_exists "PAGER" "less" "more"

export PATH="$HOME/.local/bin:$PATH"

if [ "$(uname -s)" = "Darwin" ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

if [ -f "$HOME/.secrets" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.secrets"
fi

_meow_source_component_env_scripts() {
  if [ -d "${MEOW}/.installed/components" ]; then
    local component_link
    local component_name
    local env_script

    for component_link in "${MEOW}/.installed/components"/*; do
      if [ ! -L "$component_link" ]; then
        continue
      fi

      component_name=$(basename "$component_link")

      env_script="${MEOW}/components/${component_name}/scripts/env.sh"
      if [ -f "$env_script" ]; then
        # shellcheck source=/dev/null
        source "$env_script"
      fi
    done
  fi
}

_meow_source_component_env_scripts

unset -f _meow_set_if_command_exists
unset -f _meow_source_component_env_scripts
