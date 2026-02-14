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
# @file: components/shell-essential/scripts/init.sh
# @brief: Initialization script for essential shell tools and development environment.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED=1

# Add GNU coreutils and findutils to PATH on macOS (for cross-platform compatibility)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Prefer GNU versions over BSD versions for consistent behavior across platforms
  if [[ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ]]; then
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  fi
  if [[ -d "/opt/homebrew/opt/findutils/libexec/gnubin" ]]; then
    export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
  fi
fi

# Source config library for shell functions (used by meowctl)
if [[ -f "${MEOW:-$HOME/.meow}/lib/config/config.sh" ]]; then
    source "${MEOW:-$HOME/.meow}/lib/config/config.sh"
fi

# Initialize variables to prevent nounset errors
# RPS1-4 are right-side prompts (main, continuation, secondary, debug)
export RPS1="${RPS1:-}"
export RPS2="${RPS2:-}"
export RPS3="${RPS3:-}"
export RPS4="${RPS4:-}"
export STARSHIP_JOBS_COUNT="${STARSHIP_JOBS_COUNT:-0}"

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
  if [ -n "${ALACRITTY_LOG:-}" ] || [ "${TERM_PROGRAM:-}" = "Alacritty" ] || [ -n "${ALACRITTY_WINDOW_ID:-}" ] || [ "${TERM_PROGRAM:-}" = "Ghostty" ] || [ "${TERM_PROGRAM:-}" = "ghostty" ] || [ "${TERM:-}" = "xterm-ghostty" ] || [ "${TERM:-}" = "xterm-ghostty-256color" ]; then
    export ZSH_TMUX_AUTOSTART=true
  else
    export ZSH_TMUX_AUTOSTART=false
  fi
fi

if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: sourcing $HOME/.oh-my-zsh/oh-my-zsh.sh"
  else
    # Temporarily disable nounset for oh-my-zsh compatibility (if it was set)
    # Save the state first
    case $- in
      *u*) local restore_nounset=1 ;;
      *) local restore_nounset=0 ;;
    esac
    set +u 2>/dev/null || true
    source "$HOME/.oh-my-zsh/oh-my-zsh.sh"
    # Restore nounset only if it was set before
    [[ $restore_nounset -eq 1 ]] && set -u 2>/dev/null || true
  fi
fi

# Ensure the real `duf` binary is reachable (oh-my-zsh may define `duf` alias).
if command -v duf >/dev/null 2>&1; then
  unalias duf >/dev/null 2>&1 || true
  alias df='duf'
fi

if command -v nvim >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: setting vim and vi aliases to nvim"
  fi
  alias vim='nvim'
  alias vi='nvim'
fi

# Bat aliases for common use cases
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat --paging=always'
  alias bathelp='bat --plain --language=help'
  # Usage: command --help | bathelp
  help() {
    "$@" --help 2>&1 | bathelp
  }
fi

# Ripgrep aliases
if command -v rg >/dev/null 2>&1; then
  alias rgh='rg --hidden'              # Search hidden files
  alias rgi='rg --no-ignore'           # Ignore .gitignore rules
  alias rgf='rg --files'               # List files that would be searched
  alias rgl='rg --files-with-matches'  # Only show filenames with matches
fi

# Eza aliases for better ls experience
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias l='eza -l'
  alias la='eza -la'
  alias ll='eza -l --git'
  alias tree='eza --tree'
  alias lt='eza --tree --level=2'
  alias lta='eza --tree --level=2 -a'
fi

# Git aliases (if not using oh-my-zsh git plugin)
if command -v git >/dev/null 2>&1; then
  alias g='git'
  alias gs='git status'
  alias gd='git diff'
  alias ga='git add'
  alias gc='git commit'
  alias gp='git push'
  alias gl='git pull'
  alias glog='git log --oneline --graph --decorate'
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
    
    # Configure FZF to use fd for file search if available
    if command -v fd >/dev/null 2>&1; then
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    
    # Configure FZF to use bat for file preview if available
    if command -v bat >/dev/null 2>&1; then
      export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -1 {}'"
    fi
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

if command -v direnv >/dev/null 2>&1; then
  if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
    echo "INFO: initializing direnv"
  fi
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "DRY-RUN: evaluating direnv hook command"
  else
    eval "$(direnv hook zsh)"
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

# Theme color configuration
MEOW_CONFIG_DIR="${MEOW_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/meow}"

_meow_source_theme_colors() {
  [[ -f "$MEOW_CONFIG_DIR/fzf/colors.sh" ]] && source "$MEOW_CONFIG_DIR/fzf/colors.sh" 2>/dev/null || true
  [[ -f "$MEOW_CONFIG_DIR/eza/colors.sh" ]] && source "$MEOW_CONFIG_DIR/eza/colors.sh" 2>/dev/null || true
  [[ -f "$MEOW_CONFIG_DIR/zsh/colors.sh" ]] && source "$MEOW_CONFIG_DIR/zsh/colors.sh" 2>/dev/null || true
}

meow-theme() {
  "${MEOW:-$HOME/.meow}/components/shell-essential/scripts/meow-theme" "$@"
  local exit_code=$?
  
  # Reload environment variables after theme changes
  case "${1:-apply}" in
    toggle|apply|preset|auto|"")
      _meow_source_theme_colors
      ;;
  esac
  
  return $exit_code
}

# Source theme colors on shell initialization
_meow_source_theme_colors

# Load shell completions for meowctl and meow-theme
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
