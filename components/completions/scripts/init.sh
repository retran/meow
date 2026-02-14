#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/completions/scripts/init.sh
# @brief: Initialize shell completions for meow tools
# @author: Andrew Vasilyev
# @license: MIT

if [ -n "${_COMPONENT_COMPLETIONS_INIT_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_COMPLETIONS_INIT_SOURCED=1

MEOW="${MEOW:-$HOME/.meow}"

# Load completions based on shell type
if [ -n "$ZSH_VERSION" ]; then
  # Zsh completion
  fpath=("$MEOW/completions/zsh" $fpath)
  
  # Force reload of completion system
  autoload -Uz compinit
  compinit -i
  
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: Loaded zsh completions for meowctl and meow-theme"
  fi
elif [ -n "$BASH_VERSION" ]; then
  # Bash completion
  if [ -f "$MEOW/completions/bash/meowctl-completion.bash" ]; then
    source "$MEOW/completions/bash/meowctl-completion.bash"
  fi
  
  if [ -f "$MEOW/completions/bash/meow-theme-completion.bash" ]; then
    source "$MEOW/completions/bash/meow-theme-completion.bash"
  fi
  
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: Loaded bash completions for meowctl and meow-theme"
  fi
fi
