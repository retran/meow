#!/usr/bin/env bash

if [[ -n "${_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_CORE_DEVELOPMENT_INIT_SOURCED=1

# Git commit message preparation function
_prepare_commit_message() {
  # The original sed '/^/d' command would delete all input,
  # preventing the function from processing the commit message.
  # It has been removed to allow the message content to flow through
  # to the read commands and fmt for proper formatting.
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
