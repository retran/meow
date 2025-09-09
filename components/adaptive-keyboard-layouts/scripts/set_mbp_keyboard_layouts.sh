#!/usr/bin/env bash
# @file:    components/adaptive-keyboard-layouts/scripts/set_mbp_keyboard_layouts.sh
# @brief:   Installation or configuration script for adaptive-keyboard-layouts component.
# @author:  Andrew Vasilyev
# @license: MIT
#

source "${MEOW:-$HOME/.meow}/components/adaptive-keyboard-layouts/scripts/macos_keyboard.sh"

set_macos_keyboard_layouts "mbp"
