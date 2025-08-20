#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_SESSION_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_SESSION_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/tools.sh"

_initialize_session() {
  step_header "Initializing package manager"

  if [[ "$IS_ALPINE" == "true" ]]; then
    info "" "Alpine Linux detected. Using apk."
    setup_apk ""
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    info "" "Debian-based system detected. Using APT."
    setup_apt ""
  elif [[ "$IS_ARCH" == "true" ]]; then
    info "" "Arch Linux detected. Using pacman."
    setup_pacman ""
  elif [[ "$IS_MACOS" == "true" ]]; then
    info "" "macOS system detected. Using Homebrew."
    setup_homebrew ""
  else
    warning "" "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  ensure_yq || {
    error_msg "" "Failed to ensure yq installation"
    return 1
  }
}

_finalize_session() {
  if [[ "$IS_ALPINE" == "true" ]]; then
    cleanup_apk ""
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt ""
  elif [[ "$IS_ARCH" == "true" ]]; then
    cleanup_pacman ""
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew ""
  fi
}
