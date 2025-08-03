#!/usr/bin/env bash

# scripts/setup-shell-essential.sh - Script to set up essential shell environment

set -euo pipefail

PRESET="$1"
MEOW="$2"
INDENT_LEVEL="${3:-0}"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/system/tmux.sh"
source "${MEOW}/lib/system/zsh.sh"

main() {
  local indent_level="$INDENT_LEVEL"
  local child_indent=$((indent_level + 1))

  step_header "$indent_level" "Running Setup Script for 'shell-essential'"

  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    action_msg "$child_indent" "Running Linux-specific setup (Zsh plugins)..."
    
    local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ -d "$zsh_custom_dir" ]]; then
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-autosuggestions" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "${zsh_custom_dir}/plugins/zsh-autosuggestions" >/dev/null 2>&1
      fi
      if [[ ! -d "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" ]]; then
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
      fi
      success_tick_msg "$child_indent" "Zsh plugins checked/installed."
    else
      indented_warning "$child_indent" "Oh My Zsh dir not found at '$zsh_custom_dir'. Skipping Zsh plugins."
    fi
  fi

  if command -v tmux >/dev/null 2>&1; then
    info "$indent_level" "Configuring tmux..."
    configure_tmux "$child_indent" || true
  fi

  if command -v zsh >/dev/null 2>&1; then
    info "$indent_level" "Configuring zsh..."
    configure_zsh "$child_indent" || true
  fi

  success_tick_msg "$indent_level" "Essential shell environment setup complete"
}

main "$@"
