#!/usr/bin/env zsh

# ~/.zprofile - Sourced on login.

if [[ -f "$DOTFILES_DIR/config/env/env.sh" ]]; then
  . "$DOTFILES_DIR/config/env/env.sh"
fi