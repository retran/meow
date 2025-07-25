#!/usr/bin/env zsh

ZSH_THEME="robbyrussell"

plugins=(
  macos
  brew

  copyfile
  copypath
  urltools
  safe-paste
  command-not-found
  encode64
  dotenv

  tmux
  ssh
  colored-man-pages

  git
  git-lfs
  git-extras
  git-escape-magic
  github
  gh

  docker
  docker-compose
  gcloud
  python
  dotnet
  bazel
  gradle
  vscode
)

if [[ -n "$GHOSTTY_BIN_DIR" ]]; then
  ZSH_TMUX_AUTOSTART=true
else
  ZSH_TMUX_AUTOSTART=false
fi

export ZSH="$HOME/.oh-my-zsh"
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ -f "$MEOW/config/aliases/aliases.sh" ]]; then . "$MEOW/config/aliases/aliases.sh"; fi

if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  . "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  . "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if command -v pyenv &>/dev/null; then
  eval "$(pyenv init -)"
fi

if ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    eval $(env COMMANDLINE="${words[1, $CURRENT]}" _TOGGL_COMPLETE=complete-zsh toggl)
  }
  compdef _toggl toggl
fi

if [[ -f $HOME/fzf.zsh ]]; then . $HOME/.fzf.zsh; fi

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

eval "$(starship init zsh)"