#!/usr/bin/env bash

if [[ -n "${_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED=1

# Git commit message preparation function
_prepare_commit_message() {
  sed '/^/d' |
    (
      read -r subject
      echo "$subject"

      read -r empty_line
      echo "$empty_line"

      fmt -s -w 72
    )
}

# AI-assisted git commit alias (if meow is available)
if command -v meow >/dev/null 2>&1; then
  alias mgc='git diff --staged | meow g -t commit | _prepare_commit_message | git commit -F - --edit'
fi
