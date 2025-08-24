#!/usr/bin/env bash

# Helper function for safe string formatting, injected by the inliner script.
source "${MEOW}/lib/core/ui.sh"

if [[ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    local actual_version
    actual_version=$(yq --version | awk '{print $4}')

    if [[ "$actual_version" == "$YQ_VERSION" ]]; then
      ui_verbose_info "$(_f "⇒ yq %s is already installed." "$YQ_VERSION")"
      return 0
    fi

    ui_action_warning "$(_f "Found yq, but version mismatch. Expected: '%s', Found: '%s'" "$YQ_VERSION" "$actual_version")"
  fi

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "Would install yq v${YQ_VERSION} to /usr/local/bin/yq"
    dry_run_command_ui_info "curl -fsSL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_\$(uname -s | tr '[:upper:]' '[:lower:]')_\$(uname -m | sed 's/x86_64/amd64/') -o /tmp/yq"
    dry_run_command_ui_info "sudo mv /tmp/yq /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq"
    return 0
  fi

  ui_action_start "$(_f "Installing yq v%s..." "$YQ_VERSION")"

  local OS ARCH BIN_NAME URL DEST TMPBIN

  case "$(uname -s)" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    *)
      ui_action_error "$(_f "Unsupported OS: %s" "$(uname -s)")"
      return 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64 | aarch64 | arm64)
      [[ "$(uname -m)" == "x86_64" ]] && ARCH="amd64" || ARCH="arm64"
      ;;
    *)
      ui_action_error "$(_f "Unsupported architecture: %s" "$(uname -m)")"
      return 1
      ;;
  esac

  BIN_NAME="yq_${OS}_${ARCH}"
  URL="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${BIN_NAME}"
  DEST="/usr/local/bin/yq"
  TMPBIN="/tmp/${BIN_NAME}"

  if curl -fsSL "$URL" -o "$TMPBIN"; then
    sudo mv "$TMPBIN" "$DEST" || return 1
    sudo chmod +x "$DEST" || return 1
    ui_action_success "$(_f "yq v%s installed to %s" "$YQ_VERSION" "$DEST")"
    return 0
  else
    ui_action_error "$(_f "Failed to download yq from %s" "$URL")"
    return 1
  fi
}
