#!/usr/bin/env bash

source "${MEOW:-$HOME/.meow}/components/adaptive-keyboard-layouts/scripts/macos_keyboard.sh"

if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Setting macOS keyboard layouts to 'das'"
fi

if [ "$MEOW_DRY_RUN" = "true" ]; then
  echo "DRY-RUN: Would have set keyboard layouts"
else
  set_macos_keyboard_layouts "das"
fi
