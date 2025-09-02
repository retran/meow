#!/usr/bin/env bash

if [ -n "${_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_SHELL_ESSENTIAL_ENV_SOURCED=1

# Add FZF to PATH if available and not already in PATH
for fzf_path in "/opt/homebrew/opt/fzf/bin" "/usr/local/opt/fzf/bin" "/usr/share/fzf/bin"; do
  if [[ -d "$fzf_path" && ":$PATH:" != *":$fzf_path:"* ]]; then
    if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
      echo "INFO: Adding $fzf_path to PATH" >&2
    fi
    if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
      export PATH="${PATH:+${PATH}:}$fzf_path"
    else
      echo "DRY-RUN: Would add $fzf_path to PATH" >&2
    fi
    break
  fi
done
