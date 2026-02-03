#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/shell-essential/scripts/env.sh
# @brief: Environment configuration script for shell development tools and paths.
# @author: Andrew Vasilyev
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

# Set default editor to neovim if available
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  export GIT_EDITOR="nvim"
fi

# Configure ripgrep
if command -v rg >/dev/null 2>&1; then
  export RIPGREP_CONFIG_PATH="${MEOW}/components/shell-essential/config/ripgrep/.ripgreprc"
fi

# Load theme-generated configurations
MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"

# Source FZF colors if available
if [[ -f "$MEOW_CONFIG_DIR/fzf/colors.sh" ]]; then
  source "$MEOW_CONFIG_DIR/fzf/colors.sh"
fi

# Source eza colors if available
if [[ -f "$MEOW_CONFIG_DIR/eza/colors.sh" ]]; then
  source "$MEOW_CONFIG_DIR/eza/colors.sh"
fi

# Source zsh/LS_COLORS if available
if [[ -f "$MEOW_CONFIG_DIR/zsh/colors.sh" ]]; then
  source "$MEOW_CONFIG_DIR/zsh/colors.sh"
fi
