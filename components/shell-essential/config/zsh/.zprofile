#!/usr/bin/env zsh

# Source meow config variables

MEOW_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/meow/config.yaml"
if [[ -f "$MEOW_CONFIG_FILE" ]]; then
  export MEOW_CONFIG_FILE
fi

MEOW_STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/meow/starship.toml"
if [[ -f "$MEOW_STARSHIP_CONFIG" ]]; then
  export STARSHIP_CONFIG="$MEOW_STARSHIP_CONFIG"
fi

# Source core meow environment setup
if [[ -f "$HOME/.meow/lib/env/env.sh" ]]; then
  . "$HOME/.meow/lib/env/env.sh"
fi
