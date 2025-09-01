#!/usr/bin/env bash

if [ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

ensure_yq() {
  if command -v yq >/dev/null 2>&1; then
    local actual_version version_output
    version_output=$(yq --version 2>/dev/null || echo "")

    # Try multiple parsing strategies for different yq version output formats
    actual_version=$(echo "$version_output" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # If still empty, try extracting from different fields
    if [ -z "$actual_version" ]; then
      actual_version=$(echo "$version_output" | awk '{for(i=1;i<=NF;i++) if($i ~ /^v?[0-9]+\.[0-9]+\.[0-9]+$/) print $i}' | head -1)
    fi

    # Normalize version format (ensure it starts with 'v')
    if [ -n "$actual_version" ] && [[ ! "$actual_version" =~ ^v ]]; then
      actual_version="v$actual_version"
    fi

    if [ "$actual_version" = "$YQ_VERSION" ]; then
      ui_verbose_info "$(_f "⇒ yq %s is already installed and matches the required version." "$YQ_VERSION")"
      return 0
    fi

    ui_action_warning "$(_f "Found yq, but version mismatch or parse error (expected: '%s', found: '%s', raw: '%s'). Attempting to install required version." "$YQ_VERSION" "$actual_version" "$version_output")"
  fi

  if is_dry_run; then
    dry_run_ui_info "Would install yq v${YQ_VERSION}."

    local dry_run_os dry_run_arch
    case "$(uname -s)" in
      Linux) dry_run_os="linux" ;;
      Darwin) dry_run_os="darwin" ;;
      *) dry_run_os="unknown_os" ;;
    esac

    case "$(uname -m)" in
      x86_64) dry_run_arch="amd64" ;;
      aarch64 | arm64) dry_run_arch="arm64" ;;
      *) dry_run_arch="unknown_arch" ;;
    esac

    local dry_run_bin_name="yq_${dry_run_os}_${dry_run_arch}"
    local dry_run_url="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${dry_run_bin_name}"
    local dry_run_tmpbin="/tmp/yq_${dry_run_os}_${dry_run_arch}_${YQ_VERSION}.tmp"
    local dry_run_dest="/usr/local/bin/yq"

    dry_run_command_ui_info "curl -fsSL \"$dry_run_url\" -o \"$dry_run_tmpbin\""
    dry_run_command_ui_info "sudo mv \"$dry_run_tmpbin\" \"$dry_run_dest\" && sudo chmod +x \"$dry_run_dest\""
    return 0
  fi

  ui_action_start "$(_f "Installing yq v%s..." "$YQ_VERSION")"

  local OS ARCH BIN_NAME URL DEST TMPBIN

  case "$(uname -s)" in
    Linux) OS="linux" ;;
    Darwin) OS="darwin" ;;
    *)
      ui_action_error "$(_f "Unsupported OS: %s. Cannot install yq." "$(uname -s)")"
      return 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *)
      ui_action_error "$(_f "Unsupported architecture: %s. Cannot install yq." "$(uname -m)")"
      return 1
      ;;
  esac

  BIN_NAME="yq_${OS}_${ARCH}"
  URL="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${BIN_NAME}"
  DEST="/usr/local/bin/yq"
  TMPBIN="/tmp/yq_${OS}_${ARCH}_${YQ_VERSION}.tmp"

  ui_verbose_info "$(_f "Attempting to download yq from: %s" "$URL")"

  if curl -fsSL "$URL" -o "$TMPBIN"; then
    ui_verbose_info "$(_f "Downloaded yq to temporary location: %s" "$TMPBIN")"
    if sudo mv "$TMPBIN" "$DEST"; then
      if sudo chmod +x "$DEST"; then
        ui_action_success "$(_f "yq v%s successfully installed to %s." "$YQ_VERSION" "$DEST")"
        return 0
      else
        ui_action_error "$(_f "Failed to make yq executable at %s." "$DEST")"
        return 1
      fi
    else
      ui_action_error "$(_f "Failed to move yq binary from %s to %s." "$TMPBIN" "$DEST")"
      return 1
    fi
  else
    ui_action_error "$(_f "Failed to download yq from %s. Please check your network connection or the URL." "$URL")"
    return 1
  fi
}
