#!/usr/bin/env bash

COMPONENT_NAME="$1"
MEOW="$2"

if [ -z "$MEOW" ]; then
  echo "Error: Path to dotfiles repository (MEOW) not provided as the second argument." >&2
  return 1
fi

if [ ! -d "$MEOW" ]; then
  echo "Error: Dotfiles repository path is not a directory: '$MEOW'" >&2
  return 1
fi

MEOW_ABSOLUTE_PATH="$(cd "$MEOW" && pwd -P)" || {
  echo "Error: Could not canonicalize path for '$MEOW'." >&2
  return 1
}
MEOW="$MEOW_ABSOLUTE_PATH"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if ! command -v npm >/dev/null 2>&1; then
  ui_warning "npm command not found. Skipping Node.js configuration."
  return 0
fi

ui_action_start "Configuring npm for global packages without sudo."

npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Verbose: Creating npm global directory: '$npm_global_path'" >&2
fi

if [ "$MEOW_DRY_RUN" != "true" ]; then
  mkdir -p "$npm_global_path" || {
    echo "Error: Failed to create npm global installation directory: '$npm_global_path'." >&2
    return 1
  }
fi

if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Verbose: Setting npm prefix to: '$npm_global_path'" >&2
fi

if [ "$MEOW_DRY_RUN" != "true" ]; then
  npm config set prefix "$npm_global_path" || {
    echo "Error: Failed to set npm prefix to '$npm_global_path'." >&2
    return 1
  }
fi

ui_action_success "NPM configured successfully."
