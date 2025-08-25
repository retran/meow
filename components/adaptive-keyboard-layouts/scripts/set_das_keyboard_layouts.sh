#!/usr/bin/env bash

source "${MEOW:-$HOME/.meow}/lib/system/macos_keyboard.sh"

if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Setting macOS keyboard layouts to 'das' with order 0"
fi

if [ "$MEOW_DRY_RUN" = "true" ]; then
  echo "DRY-RUN: Would have set keyboard layouts"
else
  set_macos_keyboard_layouts "das" 0
fi
