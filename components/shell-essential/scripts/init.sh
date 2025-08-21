#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_INIT_SOURCED=1

export ZSH_THEME="robbyrussell"

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

conditional_plugins=(git git-lfs git-escape-magic gitignore)

command -v gh &>/dev/null && conditional_plugins+=(github gh)
command -v ssh &>/dev/null && conditional_plugins+=(ssh)
command -v docker &>/dev/null && conditional_plugins+=(docker docker-compose)
command -v code &>/dev/null && conditional_plugins+=(vscode)
command -v http &>/dev/null && conditional_plugins+=(httpie)
command -v go &>/dev/null && conditional_plugins+=(golang)
command -v node &>/dev/null && conditional_plugins+=(node npm)
command -v eza &>/dev/null && conditional_plugins+=(eza)
command -v tmux &>/dev/null && conditional_plugins+=(tmux)
command -v brew &>/dev/null && conditional_plugins+=(brew)

os_plugins=()
[[ "$OSTYPE" == "darwin"* ]] && os_plugins+=(macos)

export plugins=("${base_plugins[@]}" "${conditional_plugins[@]}" "${os_plugins[@]}")

if [[ -n "$ALACRITTY_LOG" ]]; then
  export ZSH_TMUX_AUTOSTART=true
else
  export ZSH_TMUX_AUTOSTART=false
fi

export ZSH="$HOME/.oh-my-zsh"
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

command -v nvim >/dev/null 2>&1 && {
  alias vim='nvim'
  alias vi='nvim'
}

command -v bat >/dev/null 2>&1 && alias cat='bat -p'
command -v fd &>/dev/null && alias find='fd'

if command -v rg &>/dev/null; then
  alias rg='rg --color=auto'
  function grep_with_rg() {
    if [ -t 1 ]; then
      command rg --color=auto "$@"
    else
      command grep "$@"
    fi
  }
  if ! type grep | grep -q 'function'; then
    unalias grep 2>/dev/null || true
    alias grep='grep_with_rg'
  fi
fi

command -v fzf &>/dev/null && source <(fzf --zsh)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v starship &>/dev/null && eval "$(starship init zsh)"
