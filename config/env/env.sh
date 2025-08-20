#!/usr/bin/env bash

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

# Local bin path
export PATH="$HOME/.local/bin:$PATH"

# macOS Homebrew configuration
if [[ "$(uname -s)" == "Darwin" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Load secrets if available
if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi

# Source env scripts from installed components
if [[ -d "${MEOW}/.installed/components" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for component_link in "${MEOW}/.installed/components"/*; do
    [[ -L "$component_link" ]] || continue
    component_name=$(basename "$component_link")
    env_script="${MEOW}/components/${component_name}/env.sh"
    if [[ -f "$env_script" ]]; then
      # shellcheck source=/dev/null
      source "$env_script"
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Source env scripts from installed presets
if [[ -d "${MEOW}/.installed/presets" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for preset_link in "${MEOW}/.installed/presets"/*; do
    [[ -L "$preset_link" ]] || continue
    preset_name=$(basename "$preset_link")
    env_script="${MEOW}/presets/${preset_name}/env.sh"
    if [[ -f "$env_script" ]]; then
      # shellcheck source=/dev/null
      source "$env_script"
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Function to check if plugin is available (component installed)
_is_plugin_available() {
  local plugin="$1"
  local plugin_file="${MEOW}/plugins/${plugin}/plugin.yaml"

  [[ -f "$plugin_file" ]] || return 1

  local available_when
  available_when=$(yq eval '.available_when' "$plugin_file" 2>/dev/null)

  # If no available_when specified, plugin is always available
  if [[ -z "$available_when" || "$available_when" == "null" ]]; then
    return 0
  fi

  # Check if required component is installed
  local component_symlink="${MEOW}/.installed/components/${available_when}"
  [[ -L "$component_symlink" ]]
}

# Source plugin environment scripts
if [[ -d "${MEOW}/.installed/plugins" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for plugin_link in "${MEOW}/.installed/plugins"/*; do
    [[ -L "$plugin_link" ]] || continue
    plugin_name=$(basename "$plugin_link")

    # Only load env.sh if plugin is available
    if _is_plugin_available "$plugin_name"; then
      env_script="${MEOW}/plugins/${plugin_name}/env.sh"
      if [[ -f "$env_script" ]]; then
        # shellcheck source=/dev/null
        source "$env_script"
      fi
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi
