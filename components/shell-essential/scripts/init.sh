#!/usr/bin/env bash
# @file:    components/shell-essential/scripts/init.sh
# @brief:   Initialization script for essential shell tools and development environment.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED=1

# Only set ZSH_THEME if starship is not available
if ! command -v starship >/dev/null 2>&1; then
  export ZSH_THEME="robbyrussell"
fi

base_plugins=(
  safe-paste
  command-not-found
  colored-man-pages
  man
  colorize
  copyfile
  copypath
  urltools
  encode64
)

conditional_plugins=()
if command -v gh >/dev/null 2>&1; then
  conditional_plugins+=("github")
fi

if command -v ssh >/dev/null 2>&1; then
  conditional_plugins+=("ssh")
fi

if command -v docker >/dev/null 2>&1; then
  conditional_plugins+=("docker" "docker-compose")
fi

if command -v code >/dev/null 2>&1; then
  conditional_plugins+=("vscode")
fi

if command -v http >/dev/null 2>&1; then
  conditional_plugins+=("httpie")
fi

if command -v go >/dev/null 2>&1; then
  conditional_plugins+=("golang")
fi

if command -v node >/dev/null 2>&1; then
  conditional_plugins+=("node" "npm")
fi

if command -v eza >/dev/null 2>&1; then
  conditional_plugins+=("eza")
fi

if command -v tmux >/dev/null 2>&1; then
  conditional_plugins+=("tmux")
fi

if command -v brew >/dev/null 2>&1; then
  conditional_plugins+=("brew")
fi

os_plugins=()
if [ "${OSTYPE#darwin}" != "$OSTYPE" ]; then
  os_plugins+=("macos")
fi

plugins=("${base_plugins[@]}" "${conditional_plugins[@]}" "${os_plugins[@]}")
export plugins

# Set tmux autostart based on terminal detection (only if tmux is available)
if command -v tmux >/dev/null 2>&1; then
  if [ -n "$ALACRITTY_LOG" ] || [ "$TERM_PROGRAM" = "Alacritty" ] || [ -n "$ALACRITTY_WINDOW_ID" ]; then
    export ZSH_TMUX_AUTOSTART=true
  else
    export ZSH_TMUX_AUTOSTART=false
  fi
fi

if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: sourcing $HOME/.oh-my-zsh/oh-my-zsh.sh"
  else
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
  fi
fi

if command -v nvim >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: setting vim and vi aliases to nvim"
  fi
  alias vim='nvim'
  alias vi='nvim'
fi

if command -v fzf >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: sourcing fzf zsh completion"
  fi
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: sourcing fzf completion"
  else
    # shellcheck disable=SC1090
    source <(fzf --zsh)
  fi
fi

if command -v zoxide >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: initializing zoxide"
  fi
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: evaluating zoxide init command"
  else
    eval "$(zoxide init zsh --cmd cd)"
  fi
fi

if command -v starship >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: initializing starship"
  fi
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: evaluating starship init command"
  else
    eval "$(starship init zsh)"
  fi
fi
