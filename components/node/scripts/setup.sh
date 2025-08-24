#!/usr/bin/env bash

# COMPONENT_NAME is the first argument, but it's unused in this script.
# It is kept to preserve the original argument parsing structure.
COMPONENT_NAME="$1"
# MEOW is the second argument, expected to be the path to the dotfiles repository root.
# It is used to locate library scripts like platform.sh and ui.sh.
MEOW="$2"

# Validate that MEOW (dotfiles repository path) is provided.
if [ -z "$MEOW" ]; then
  echo "Error: Path to dotfiles repository (MEOW) not provided as the second argument." >&2
  return 1
fi

# Validate that MEOW points to an existing directory.
if [ ! -d "$MEOW" ]; then
  echo "Error: Dotfiles repository path is not a directory: '$MEOW'" >&2
  return 1
fi

# Canonicalize MEOW to an absolute path for reliable sourcing.
# This ensures that sourced scripts can find their own relative paths correctly,
# regardless of the current working directory when this script is run.
# Using a subshell with 'cd' prevents altering the current script's working directory.
MEOW_ABSOLUTE_PATH="$(cd "$MEOW" && pwd -P)" || {
  echo "Error: Could not canonicalize path for '$MEOW'." >&2
  return 1
}
MEOW="$MEOW_ABSOLUTE_PATH"

# Source necessary library scripts.
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

# Check if npm is installed and accessible.
if ! command -v npm >/dev/null 2>&1; then
  ui_warning "npm command not found. Skipping Node.js configuration."
  # Return 0 to indicate a non-fatal skip, consistent with the original script's behavior.
  return 0
fi

ui_action_start "Configuring npm for global packages without sudo."

# Determine the npm global installation path.
# It uses the NPM_CONFIG_PREFIX environment variable if set,
# otherwise, it defaults to "${HOME}/.npm-global".
npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

# Create the global npm directory if it doesn't already exist.
mkdir -p "$npm_global_path" || {
  # If mkdir fails, print an error message to stderr and return 1.
  echo "Error: Failed to create npm global installation directory: '$npm_global_path'." >&2
  return 1
}

# Set npm's prefix configuration to the determined global path.
npm config set prefix "$npm_global_path" || {
  # If setting the npm prefix fails, print an error message to stderr and return 1.
  echo "Error: Failed to set npm prefix to '$npm_global_path'." >&2
  return 1
}

ui_action_success "NPM configured successfully."
