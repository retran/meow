#!/usr/bin/env zsh

# config/shells/zsh/.zshrc - Zsh configuration file

# Ensure DOTFILES_DIR is set
if [[ -z "$DOTFILES_DIR" ]]; then
  echo "Error: DOTFILES_DIR is not set. Please define it before sourcing this file."
  return 1
fi
# Source environment configuration
. "$DOTFILES_DIR/config/env/env.sh"

. "$DOTFILES_DIR/lib/core/colors.sh"
. "$DOTFILES_DIR/lib/core/ui.sh"
. "$DOTFILES_DIR/lib/greeting/greeting.sh"

# Source aliases
. "$DOTFILES_DIR/config/aliases/aliases.sh"

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

  1password

  docker
  docker-compose
  gcloud

  python

  dotnet

  bazel
  gradle

  vscode
)

# Only autostart tmux when running in Kitty
if [[ -n "$KITTY_PID" ]]; then
  ZSH_TMUX_AUTOSTART=true
else
  ZSH_TMUX_AUTOSTART=false
fi

source "$ZSH/oh-my-zsh.sh"

. "/opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
. "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
. "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Toggl completion
_toggl() {
  eval $(env COMMANDLINE="${words[1,$CURRENT]}" _TOGGL_COMPLETE=complete-zsh toggl)
}

if [[ "$(basename -- "${(%):-%N}")" != "_toggl" ]]; then
  compdef _toggl toggl
fi

# starship prompt initialization
eval "$(starship init zsh)"

# Only show greeting in the first tmux pane
if [[ "$TMUX_PANE" == "%0" ]]; then
  show_greeting
fi
