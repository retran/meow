#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tool-installers/scripts/init.sh
# @brief: Initialize mise and other tool installers in shell
# @author: Andrew Vasilyev
# @license: MIT

if [ -n "${_COMPONENT_TOOL_INSTALLERS_INIT_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_TOOL_INSTALLERS_INIT_SOURCED=1

# Activate mise if available
if command -v mise >/dev/null 2>&1; then
  # Detect shell and activate mise
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(mise activate zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(mise activate bash)"
  fi
fi
