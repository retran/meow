#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tmux/scripts/load-theme.sh
# @brief: Load tmux theme based on meow theme config
# @author: Andrew Vasilyev
# @license: MIT

set -euo pipefail

MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
THEME_FILE="$MEOW_CONFIG_DIR/tmux/theme.conf"

if [[ -f "$THEME_FILE" ]]; then
    echo "$THEME_FILE"
    exit 0
fi

fallback="${MEOW:-$HOME/.meow}/components/tmux/config/themes/tokyonight-storm.conf"
if [[ -f "$fallback" ]]; then
  echo "$fallback"
else
  echo "$THEME_FILE"
fi
