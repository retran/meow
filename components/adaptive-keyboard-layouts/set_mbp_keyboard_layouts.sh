#!/usr/bin/env bash

# scripts/set_mbp_keyboard_layouts.sh - Script to set MacBook Pro keyboard layouts on macOS

source "${MEOW:-$HOME/.meow}/lib/system/macos_keyboard.sh"

set_macos_keyboard_layouts "mbp" 0
