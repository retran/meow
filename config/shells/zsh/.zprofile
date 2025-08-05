#!/usr/bin/env zsh

if [[ -f "$HOME/.meow/config/env/env.sh" ]]; then
  . "$HOME/.meow/config/env/env.sh"
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
