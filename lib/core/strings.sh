#!/usr/bin/env bash

# lib/core/strings.sh - Main strings loader for UI system

if [[ -n "${_LIB_CORE_STRINGS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_STRINGS_SOURCED=1

# Load the unified strings file
source "${MEOW}/lib/strings/strings.sh"
