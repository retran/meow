#!/usr/bin/env bash

# COMPONENT_NAME is the first argument, but it's unused in this script.
# It is kept to preserve the original argument parsing structure.
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
  # Return 0 to indicate a non-fatal skip, consistent with the original script's behavior.
  return 0
fi

ui_action_start "Configuring npm for global packages without sudo."

npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

mkdir -p "$npm_global_path" || {
  echo "Error: Failed to create npm global installation directory: '$npm_global_path'." >&2
  return 1
}

npm config set prefix "$npm_global_path" || {
  echo "Error: Failed to set npm prefix to '$npm_global_path'." >&2
  return 1
}

ui_action_success "NPM configured successfully."
