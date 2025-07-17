#!/usr/bin/env zsh

# ~/.zlogin - Sourced on login, after .zshrc.

if [[ -n "$TMUX" && "$TMUX_PANE" == "%0" ]]; then
  if [[ -f "$DOTFILES_DIR/lib/motd/motd.sh" ]]; then
    . "$DOTFILES_DIR/lib/motd/motd.sh"
    show_motd
  fi
fi
