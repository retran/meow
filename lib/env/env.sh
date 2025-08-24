#!/usr/bin/env bash

# Ensure the script is sourced only once per session.
if [[ -n "${_MEOW_CORE_ENV_SOURCED:-}" ]]; then
  return 0
fi
_MEOW_CORE_ENV_SOURCED=1

# Helper function to set environment variables based on available commands.
# Sets the first argument (variable name) to the path of the first command
# found in the subsequent arguments.
_meow_set_if_command_exists() {
  local var_name="$1"
  shift
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      export "$var_name"="$cmd"
      return 0
    fi
  done
  return 1 # No command found
}

# Set MEOW path, allowing override for development.
export MEOW="${MEOW:-${HOME}/.meow}"

# Detect if we're running from the development directory and adjust MEOW path.
if [[ -f "./config/env/env.sh" && -d "./presets" ]]; then
  MEOW="$(pwd)"
  export MEOW
fi

# XDG Base Directory Specification.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Locale configuration.
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Set preferred editor (fallback chain).
_meow_set_if_command_exists "EDITOR" "nvim" "vim" "nano"
if [[ -n "${EDITOR:-}" ]]; then
  export VISUAL="$EDITOR"
fi

# Set preferred pager.
_meow_set_if_command_exists "PAGER" "less" "more"

# Add local bin to PATH.
export PATH="$HOME/.local/bin:$PATH"

# macOS Homebrew configuration.
if [[ "$(uname -s)" == "Darwin" ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Load secrets if available.
if [[ -f "$HOME/.secrets" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.secrets"
fi

# Function to source environment scripts for installed components.
_meow_source_component_env_scripts() {
  if [[ -d "${MEOW}/.installed/components" ]]; then
    for component_link in "${MEOW}/.installed/components"/*; do
      # In Bash, if no files match the glob, component_link will be the literal pattern.
      # The -L check handles this gracefully, evaluating to false for a non-existent literal.
      [[ -L "$component_link" ]] || continue # Process only symbolic links

      local component_name
      component_name=$(basename "$component_link")

      local env_script="${MEOW}/components/${component_name}/scripts/env.sh"
      if [[ -f "$env_script" ]]; then
        # shellcheck source=/dev/null
        source "$env_script"
      fi
    done
  fi
}

# Load component environment scripts.
_meow_source_component_env_scripts

# Clean up helper functions to keep them private to this file's sourcing context.
unset -f _meow_set_if_command_exists
unset -f _meow_source_component_env_scripts
