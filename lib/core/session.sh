#!/usr/bin/env bash

# Set strict mode for the script

# Guard against sourcing multiple times and ensure it's not run as a standalone script when sourced
if [[ -n "${_LIB_CORE_SESSION_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_SESSION_SOURCED=1

# Source core libraries
# MEOW is expected to be defined in the environment, pointing to the project root
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/tools.sh"

# Initializes the session by setting up the appropriate package manager
_initialize_session() {
  if [[ "$IS_ALPINE" = "true" ]]; then
    ui_spinner "Initializing Alpine Linux setup..." setup_apk ""
  elif [[ "$IS_DEBIAN_BASED" = "true" ]]; then
    ui_spinner "Initializing Debian/Ubuntu setup..." setup_apt ""
  elif [[ "$IS_ARCH" = "true" ]]; then
    ui_spinner "Initializing Arch Linux setup..." setup_pacman ""
  elif [[ "$IS_MACOS" = "true" ]]; then
    ui_spinner "Initializing macOS Homebrew setup..." setup_homebrew ""
  else
    ui_action_warning "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  # Ensure yq is installed
  if ! ensure_yq; then
    ui_action_error "Failed to ensure yq installation."
    return 1
  fi
}

# Finalizes the session by cleaning up resources for the appropriate package manager
_finalize_session() {
  if [[ "$IS_ALPINE" = "true" ]]; then
    cleanup_apk ""
  elif [[ "$IS_DEBIAN_BASED" = "true" ]]; then
    cleanup_apt ""
  elif [[ "$IS_ARCH" = "true" ]]; then
    cleanup_pacman ""
  elif [[ "$IS_MACOS" = "true" ]]; then
    cleanup_homebrew ""
  fi
}
