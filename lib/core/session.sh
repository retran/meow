#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_SESSION_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_SESSION_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/tools.sh"

_initialize_session() {
  if [[ "$IS_ALPINE" == "true" ]]; then
    ui_spinner "Initializing apk package manager" \
      --success "apk package manager ready" \
      --fail "apk initialization failed" \
      setup_apk ""
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    ui_spinner "Initializing APT package manager" \
      --success "APT package manager ready" \
      --fail "APT initialization failed" \
      setup_apt ""
  elif [[ "$IS_ARCH" == "true" ]]; then
    ui_spinner "Initializing pacman package manager" \
      --success "pacman package manager ready" \
      --fail "pacman initialization failed" \
      setup_pacman ""
  elif [[ "$IS_MACOS" == "true" ]]; then
    ui_spinner "Initializing Homebrew package manager" \
      --success "Homebrew package manager ready" \
      --fail "Homebrew initialization failed" \
      setup_homebrew ""
  else
    warning_msg "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  if ! ensure_yq; then
    error_msg "Failed to ensure yq installation"
    return 1
  fi
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
