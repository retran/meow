#!/usr/bin/env bash
set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/platform.sh"

INSTALL_PREFIX="${HOME}/.local/share/vscode-cli"
BIN_DIR="${HOME}/.local/bin"
BIN_PATH="${BIN_DIR}/code"

_detect_cli_target() {
  local arch
  arch="$(uname -m)"

  if [ "$IS_ALPINE" = "true" ]; then
    case "$arch" in
      x86_64)
        echo "cli-alpine-x64"
        ;;
      aarch64|arm64)
        echo "cli-alpine-arm64"
        ;;
      *)
        ui_error "VS Code CLI does not publish alpine builds for architecture '$arch'."
        return 1
        ;;
    esac
  else
    case "$arch" in
      x86_64)
        echo "cli-linux-x64"
        ;;
      aarch64|arm64)
        echo "cli-linux-arm64"
        ;;
      armv7l|armhf)
        echo "cli-linux-armhf"
        ;;
      *)
        ui_error "Unsupported architecture '$arch' for VS Code CLI."
        return 1
        ;;
    esac
  fi
}

main() {
  local os_id
  os_id="$(_detect_cli_target)" || return 1

  local download_url="https://update.code.visualstudio.com/latest/${os_id}/stable"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  if is_dry_run; then
    dry_run_ui_info "Would download VS Code CLI from: ${download_url}"
    dry_run_ui_info "Would install binary to ${INSTALL_PREFIX} and symlink to ${BIN_PATH}"
    return 0
  fi

  ui_step_header "Installing VS Code CLI (${os_id})"
  mkdir -p "$INSTALL_PREFIX" "$BIN_DIR"

  local archive_path="${tmp_dir}/vscode_cli.tar.gz"
  if ! curl -fsSL "$download_url" -o "$archive_path"; then
    ui_error "Failed to download VS Code CLI from ${download_url}"
    return 1
  fi

  tar -xf "$archive_path" -C "$tmp_dir"

  install -m 0755 "${tmp_dir}/code" "${INSTALL_PREFIX}/code"
  ln -sf "${INSTALL_PREFIX}/code" "$BIN_PATH"

  ui_action_success "VS Code CLI installed at ${BIN_PATH}"
  ui_info "Run 'code tunnel --accept-server-license-terms' to register this machine when needed."
}

main "$@"
