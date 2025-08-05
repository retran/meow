#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ -n "${_LIB_CORE_SESSION_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_SESSION_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/tools.sh"

_initialize_session() {
  local indent=0

  step_header "$indent" "Initializing package manager"

  if [[ "$IS_ALPINE" == "true" ]]; then
    indented_info "$((indent + 1))" "Alpine Linux detected. Using apk."
    setup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    indented_info "$((indent + 1))" "Debian-based system detected. Using APT."
    setup_apt "$((indent + 1))"
  elif [[ "$IS_ARCH" == "true" ]]; then
    indented_info "$((indent + 1))" "Arch Linux detected. Using pacman."
    setup_pacman "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    indented_info "$((indent + 1))" "macOS system detected. Using Homebrew."
    setup_homebrew "$((indent + 1))"
  else
    indented_warning "$((indent + 1))" "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  ensure_yq || {
    indented_error_msg "$((indent + 1))" "Failed to ensure yq installation"
    return 1
  }
}

_finalize_session() {
  local indent=0

  if [[ "$IS_ALPINE" == "true" ]]; then
    cleanup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt "$((indent + 1))"
  elif [[ "$IS_ARCH" == "true" ]]; then
    cleanup_pacman "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew "$((indent + 1))"
  fi
}
