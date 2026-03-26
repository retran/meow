# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/zellij/config/fish/conf.d/zjstatus-push-all.fish
# @brief: On every new interactive shell inside zellij (new tab, new session,
#         or session attach/switch), push all widget values to the session via
#         the zjstatus-widgets Hammerspoon plugin.
# @author: Andrew Vasilyev
# @license: MIT
#
# $ZELLIJ_SESSION_NAME is passed to the Hammerspoon IPC so Hammerspoon can add
# this session to its cache immediately — no `zellij list-sessions` call needed.
#
# Uses `hs -c` (Hammerspoon IPC) instead of `open hammerspoon://` because
# `open` is unreliable from background/non-GUI processes such as zellij panes.
#
# The call is fire-and-forget (backgrounded).  Hammerspoon's ZJStatusPushAll
# already schedules its own 4 s internal retry to survive zjstatus startup
# latency, so no sleep+retry is needed here.
#
# Firing on every new tab is intentional: it is essentially free (one
# backgrounded hs IPC call) and ensures correct widget state after session
# attach or switch, where zjstatus starts with empty slots.

if status is-interactive
    and test -n "$ZELLIJ"

    hs -c "ZJStatusPushAll('$ZELLIJ_SESSION_NAME')" 2>/dev/null &

end
