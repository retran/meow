#!/usr/bin/env bash
# @file:    components/shell-essential/scripts/env.sh
# @brief:   Environment configuration script for shell development tools and paths.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED=1

# Add FZF to PATH if available and not already in PATH
for fzf_path in "/opt/homebrew/opt/fzf/bin" "/usr/local/opt/fzf/bin" "/usr/share/fzf/bin"; do
  if [[ -d "$fzf_path" && ":$PATH:" != *":$fzf_path:"* ]]; then
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      echo "INFO: Adding $fzf_path to PATH" >&2
    fi
    if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
      export PATH="${PATH:+${PATH}:}$fzf_path"
    else
      echo "DRY-RUN: Would add $fzf_path to PATH" >&2
    fi
    break
  fi
done

# Configure npm global package path
export NPM_CONFIG_PREFIX="${HOME}/.npm-global"

if [ -d "$NPM_CONFIG_PREFIX/bin" ]; then
  if [[ ":$PATH:" != *":$NPM_CONFIG_PREFIX/bin:"* ]]; then
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      echo "INFO: Adding $NPM_CONFIG_PREFIX/bin to PATH" >&2
    fi
    if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
      export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
    else
      echo "DRY-RUN: Would add $NPM_CONFIG_PREFIX/bin to PATH" >&2
    fi
  fi
fi

# Configure pipx binary path
if [ -d "$HOME/.local/bin" ]; then
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      echo "INFO: Adding $HOME/.local/bin to PATH" >&2
    fi
    if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
      export PATH="$HOME/.local/bin:$PATH"
    else
      echo "DRY-RUN: Would add $HOME/.local/bin to PATH" >&2
    fi
  fi
fi
