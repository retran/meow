# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/zellij/config/fish/conf.d/zjstatus-daemon.fish
# @brief: Start zjstatus-daemon when entering a zellij session.
# @author: Andrew Vasilyev
# @license: MIT
#
# zjstatus-daemon is a compiled Swift binary that watches macOS system events
# (keyboard layout, network changes, battery state) and pushes updates to
# zjstatus pipe widgets instantly — no polling.
#
# It is started once per zellij session and exits automatically when the
# session ends (its parent process, zellij, is gone).

set -l _daemon "$HOME/.config/zellij/scripts/zjstatus-daemon"

if status is-interactive
    and test -n "$ZELLIJ"
    and test -x $_daemon

    # Kill any stale daemon from a previous session, then start fresh.
    # A fresh start ensures initial values are pushed to the new zjstatus instance.
    pkill -x zjstatus-daemon 2>/dev/null
    $_daemon &
    disown
end
