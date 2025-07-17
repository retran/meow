#!/usr/bin/env zsh

# ~/.zlogin - Sourced on login, after .zshrc.

if [[ -n "$TMUX" && "$TMUX_PANE" == "%0" ]]; then
  show_motd
fi