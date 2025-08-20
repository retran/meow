#!/usr/bin/env zsh

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_TOGGL_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_TOGGL_INIT_SOURCED=1

if ! command -v _toggl >/dev/null 2>&1; then
  _toggl() {
    eval "$(env COMMANDLINE="${words[1, $CURRENT]}" _TOGGL_COMPLETE=complete-zsh toggl)"
  }
  compdef _toggl toggl
fi
