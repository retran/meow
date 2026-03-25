# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/zellij/config/fish/conf.d/zjstatus-push-all.fish
# @brief: On every new interactive zellij session, register the session with
#         the zjstatus-widgets Hammerspoon plugin and request a full widget push.
# @author: Andrew Vasilyev
# @license: MIT
#
# $ZELLIJ_SESSION_NAME is passed as a URL parameter so Hammerspoon can add
# this session to its cache immediately — no `zellij list-sessions` call needed.
# The URL is opened twice: immediately (best-effort) and after 3 s to survive
# zjstatus's own startup latency.

if status is-interactive
    and test -n "$ZELLIJ"

    set -l _hs_url "hammerspoon://zjstatus-push-all?session=$ZELLIJ_SESSION_NAME"
    open $_hs_url 2>/dev/null
    sleep 3 && open $_hs_url 2>/dev/null &

end
