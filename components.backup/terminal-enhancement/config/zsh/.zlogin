#!/usr/bin/env zsh

if [[ -n "$TMUX" && "$TMUX_PANE" == "%0" ]]; then
  if [[ -f "$MEOW/lib/motd/motd.sh" ]]; then
    . "$MEOW/lib/motd/motd.sh"
    show_motd
  fi
fi
