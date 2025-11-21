#!/usr/bin/env zsh

# config/shells/zsh configuration file for Meow

autoload -Uz compinit
compinit

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
