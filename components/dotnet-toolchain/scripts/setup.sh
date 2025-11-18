#!/usr/bin/env bash
set -euo pipefail

component="$1"
MEOW_ROOT="$2"

source "${MEOW_ROOT}/lib/core/ui.sh"
source "${MEOW_ROOT}/lib/core/dry_run.sh"

DOTNET_INSTALL_DIR="${DOTNET_ROOT:-$HOME/.dotnet}"
DOTNET_CHANNEL="${DOTNET_CHANNEL:-10.0}"
DOTNET_QUALITY="${DOTNET_QUALITY:-ga}"
DOTNET_INSTALL_SCRIPT_URL="https://dot.net/v1/dotnet-install.sh"
DOTNET_TMP_DIR="${TMPDIR:-/tmp}"
_dotnet_install_script_path=""

cleanup_dotnet_install_script() {
  if [[ -n "${_dotnet_install_script_path:-}" ]]; then
    rm -f "${_dotnet_install_script_path:-}"
  fi
}
trap 'cleanup_dotnet_install_script' EXIT

install_dotnet() {
  local script_path
  mkdir -p "$DOTNET_TMP_DIR"
  script_path="$(mktemp "${DOTNET_TMP_DIR}/dotnet-install.XXXXXX.sh")"
  _dotnet_install_script_path="$script_path"

  ui_step_header "Installing .NET SDK (channel ${DOTNET_CHANNEL}, quality ${DOTNET_QUALITY})"

  if ! curl -fsSL "$DOTNET_INSTALL_SCRIPT_URL" -o "$script_path"; then
    ui_error "Failed to download dotnet-install script from $DOTNET_INSTALL_SCRIPT_URL"
    return 1
  fi

  chmod +x "$script_path"

  mkdir -p "$DOTNET_INSTALL_DIR"

  if "$script_path" --install-dir "$DOTNET_INSTALL_DIR" --channel "$DOTNET_CHANNEL" --quality "$DOTNET_QUALITY" --no-path; then
    ui_action_success ".NET SDK installed to $DOTNET_INSTALL_DIR"
  else
    ui_error "dotnet-install script failed."
    return 1
  fi
}

if is_dry_run; then
  dry_run_ui_info "$(_f \"Would download and run dotnet-install.sh --install-dir %s --channel %s --quality %s\" \"$DOTNET_INSTALL_DIR\" \"$DOTNET_CHANNEL\" \"$DOTNET_QUALITY\")"
  exit 0
fi

install_dotnet
