#!/usr/bin/env bash

if [ -n "${_LIB_DEFS_SOURCED:-}" ]; then
  return 0
fi
_LIB_DEFS_SOURCED=1

readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_COMPONENTS_DIR="${MEOW}/components"

readonly MEOW_INSTALLED_PRESETS_DIR="${MEOW}/.installed/presets"
readonly MEOW_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components"
readonly MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components-manual"
readonly MEOW_DOWNLOADS_DIR="${MEOW}/.downloads"
