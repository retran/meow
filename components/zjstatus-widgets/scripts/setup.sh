#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/zjstatus-widgets/scripts/setup.sh
# @brief: Post-install setup — reloads Hammerspoon so the plugin is active.
# @author: Andrew Vasilyev
# @license: MIT
#
MEOW="$2"

# Only meaningful on macOS
[[ "$(uname)" == "Darwin" ]] || exit 0

if ! command -v osascript >/dev/null 2>&1; then
    echo "osascript not found, skipping Hammerspoon reload"
    exit 0
fi

if ! pgrep -x Hammerspoon >/dev/null 2>&1; then
    echo "Hammerspoon is not running; skipping reload"
    exit 0
fi

if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    echo "(dry-run) Would reload Hammerspoon"
    exit 0
fi

osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"' 2>/dev/null \
    && echo "Hammerspoon reloaded" \
    || echo "Warning: failed to reload Hammerspoon"
