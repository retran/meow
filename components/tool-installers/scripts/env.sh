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

# Add mise binary to PATH
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

# Add mise shims to PATH so tools installed via mise are available in all sessions,
# including non-interactive login shells where `mise activate` has not run yet.
MISE_SHIMS_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
if [ -d "$MISE_SHIMS_DIR" ]; then
  case ":$PATH:" in
    *":$MISE_SHIMS_DIR:"*) ;;
    *) export PATH="$MISE_SHIMS_DIR:$PATH" ;;
  esac
fi
unset MISE_SHIMS_DIR

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
