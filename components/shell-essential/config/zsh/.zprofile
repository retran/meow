#!/usr/bin/env zsh

# Source meow config variables

if [[ -f "$HOME/.meowrc" ]]; then
  . "$HOME/.meowrc"
fi

# Source core meow environment setup
if [[ -f "$HOME/.meow/lib/env/env.sh" ]]; then
  . "$HOME/.meow/lib/env/env.sh"
fi
