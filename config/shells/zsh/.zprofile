#!/usr/bin/env zsh

# ~/.zprofile - Sourced on login.

if [[ -f "$HOME/.meow/config/env/env.sh" ]]; then
  . "$HOME/.meow/config/env/env.sh"
fi
