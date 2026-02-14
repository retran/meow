#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tool-installers/scripts/env.sh
# @brief: Environment configuration for tool installers (mise, pipx, cargo)
# @author: Andrew Vasilyev
# @license: MIT

if [ -n "${_COMPONENT_TOOL_INSTALLERS_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_TOOL_INSTALLERS_ENV_SOURCED=1

# Add mise to PATH if installed
if [ -d "$HOME/.local/bin" ] && command -v mise >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Add pipx binary directory to PATH
export PIPX_HOME="${PIPX_HOME:-$HOME/.local/pipx}"
export PIPX_BIN_DIR="${PIPX_BIN_DIR:-$HOME/.local/bin}"

if [ -d "$PIPX_BIN_DIR" ]; then
  # Only add if not already in PATH
  case ":$PATH:" in
    *":$PIPX_BIN_DIR:"*) ;;
    *) export PATH="$PIPX_BIN_DIR:$PATH" ;;
  esac
fi

# Add cargo bin directory to PATH if exists
if [ -d "$HOME/.cargo/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *) export PATH="$HOME/.cargo/bin:$PATH" ;;
  esac
fi
