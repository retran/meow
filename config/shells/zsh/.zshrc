#!/usr/bin/env zsh

# config/shells/zsh/.zshrc - Zsh configuration file

. "$HOME/.meow/config/env/env.sh"
. "$DOTFILES_DIR/lib/core/colors.sh"
. "$DOTFILES_DIR/lib/core/ui.sh"
. "$DOTFILES_DIR/lib/greeting/greeting.sh"
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

# Task Warrior completion
local completions_dir="$HOME/.zsh/completions"
local task_completion="$completions_dir/_task"

if [[ ! -d "$completions_dir" ]]; then
  mkdir -p "$completions_dir"
fi

if [[ ! -f "$task_completion" ]] && command -v task &>/dev/null; then
  task _zsh > "$task_completion" 2>/dev/null && success "Created Task Warrior completion file: $task_completion"
fi

# starship prompt initialization
eval "$(starship init zsh)"

# Only show greeting in the first tmux pane
if [[ "$TMUX_PANE" == "%0" ]]; then
  show_greeting
fi
