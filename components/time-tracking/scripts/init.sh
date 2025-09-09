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

if ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    local toggl_current_line_prefix
    local i=0

    # Reconstruct the command line prefix from COMP_WORDS up to COMP_CWORD
    # This loop is compatible with Bash 3.2 and later versions.
    toggl_current_line_prefix=""
    while [ "$i" -le "$COMP_CWORD" ]; do
      if [ "$i" -gt 0 ]; then
        toggl_current_line_prefix="$toggl_current_line_prefix "
      fi
      toggl_current_line_prefix="$toggl_current_line_prefix${COMP_WORDS[$i]}"
      i=$((i + 1))
    done

    eval "$(env COMMANDLINE="${toggl_current_line_prefix}" _TOGGL_COMPLETE=complete-bash toggl)"
  }

  complete -F _toggl toggl
fi
