#!/usr/bin/env bash

# lib/commands/session.sh - Shared session logic for install/update

if [[ -n "${_LIB_COMMANDS_SESSION_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_SESSION_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"

_initialize_session() {
  local indent=0
  local title="$1"
  step_header "$indent" "$title"

  if [[ "$IS_ALPINE" == "true" ]]; then
    indented_info "$((indent + 1))" "Alpine Linux detected. Using apk."
    setup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    indented_info "$((indent + 1))" "Debian-based system detected. Using APT."
    setup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    indented_info "$((indent + 1))" "macOS detected. Using Homebrew."
    setup_homebrew "$((indent + 1))"
  else
    indented_warning "$((indent + 1))" "No supported package manager found. Skipping."
  fi

  # Установка yq (GitHub-манифест v4)
  local yi=$((indent + 1))
  if ! command -v yq >/dev/null 2>&1; then
    indented_info "$yi" "Installing yq..."
    if [[ "$IS_MACOS" == "true" ]]; then
      brew install yq >/dev/null 2>&1 &&
        success_tick_msg "$yi" "yq installed via Homebrew" ||
        indented_error_msg "$yi" "Failed to install yq via Homebrew"
    else
      local arch
      arch=$(uname -m)
      case "$arch" in
      x86_64) arch=amd64 ;;
      aarch64 | arm64) arch=arm64 ;;
      *) arch=amd64 ;;
      esac
      local url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}"
      sudo wget -q "$url" -O /usr/local/bin/yq &&
        sudo chmod +x /usr/local/bin/yq &&
        success_tick_msg "$yi" "yq v4 downloaded (${arch})" ||
        indented_error_msg "$yi" "Failed to download yq binary"
    fi
  fi
}

_finalize_session() {
  local indent=0
  if [[ "$IS_ALPINE" == "true" ]]; then
    cleanup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew "$((indent + 1))"
  fi
}
