#!/usr/bin/env bash
# @file:    components/adaptive-keyboard-layouts/scripts/set_das_keyboard_layouts.sh
# @brief:   Das Keyboard specific layout configuration and switching utilities.
# @author:  Andrew Vasilyev
# @license: MIT
#

source "${MEOW:-$HOME/.meow}/components/adaptive-keyboard-layouts/scripts/macos_keyboard.sh"

if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Setting macOS keyboard layouts to 'das'"
fi

if [ "$MEOW_DRY_RUN" = "true" ]; then
  echo "DRY-RUN: Would have set keyboard layouts"
else
  set_macos_keyboard_layouts "das"
fi
