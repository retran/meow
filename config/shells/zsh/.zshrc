#!/usr/bin/env zsh

# config/shells/zsh/.zshrc - Zsh configuration file

# Source environment configuration
. "$DOTFILES_DIR/config/env/env.sh"

. "$DOTFILES_DIR/lib/core/colors.sh"
. "$DOTFILES_DIR/lib/core/ui.sh"
. "$DOTFILES_DIR/lib/motd/motd.sh"

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

# Only show motd in the first tmux pane
if [[ "$TMUX_PANE" == "%0" ]]; then
  show_motd
fi
