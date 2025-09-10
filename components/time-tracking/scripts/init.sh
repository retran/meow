#!/usr/bin/env bash
# @file:    components/time-tracking/scripts/init.sh
# @brief:   Initialization script for time tracking applications and configuration.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_TOGGL_INIT_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_TOGGL_INIT_SOURCED=1

# Set up zsh completion
if [ -n "${ZSH_VERSION:-}" ] && ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    local current_line="${BUFFER}"
    eval "$(env COMMANDLINE="${current_line}" _TOGGL_COMPLETE=complete-zsh toggl)"
  }

  if command -v compdef >/dev/null 2>&1; then
    compdef _toggl toggl
  fi
fi
