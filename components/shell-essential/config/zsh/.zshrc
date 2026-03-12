#!/usr/bin/env zsh

# config/shells/zsh configuration file for Meow

# Initialize variables to prevent nounset errors from plugins and tools
# RPS1-4 are right-side prompts (main, continuation, secondary, debug)
export RPS1="${RPS1:-}"
export RPS2="${RPS2:-}"
export RPS3="${RPS3:-}"
export RPS4="${RPS4:-}"
export STARSHIP_JOBS_COUNT="${STARSHIP_JOBS_COUNT:-0}"

autoload -Uz compinit
compinit

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write timestamp to history
setopt INC_APPEND_HISTORY        # Write to history immediately
setopt SHARE_HISTORY             # Share history across sessions
setopt HIST_IGNORE_DUPS          # Don't record duplicate commands
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entries
setopt HIST_FIND_NO_DUPS         # Don't show duplicates in search
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS         # Don't save duplicates
setopt HIST_VERIFY               # Show command with history expansion before running

# Terminal title management
autoload -Uz add-zsh-hook

function set_terminal_title() {
  # In zellij use escape sequence for pane title
  if [[ -n "$ZELLIJ" ]]; then
    printf "\033]2;%s\033\\" "$1"
  else
    # In regular terminal
    printf "\033]0;%s\007" "$1"
  fi
}

function preexec() {
  # Before command execution - show command
  local cmd="$1"
  # If it's vim/nvim, don't update title (vim will do it itself)
  if [[ "$cmd" =~ ^(vim|nvim|vi) ]]; then
    return
  fi
  set_terminal_title "$cmd"
}

function precmd() {
  # After command execution - show directory
  set_terminal_title "$(basename "$PWD")"
}

# Add hooks
add-zsh-hook preexec preexec
add-zsh-hook precmd precmd

# Source component interactive shell scripts
if [[ -d "${MEOW}/.installed/components" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for component_link in "${MEOW}/.installed/components"/*; do
    [[ -L "$component_link" ]] || continue
    component_name=$(basename "$component_link")
    init_script="${MEOW}/components/${component_name}/scripts/init.sh"
    if [[ -f "$init_script" ]]; then
      # shellcheck source=/dev/null
      source "$init_script"
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Load zsh-autosuggestions
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Load zsh-syntax-highlighting
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
