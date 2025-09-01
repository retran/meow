#!/usr/bin/env bash

if [ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

ensure_yq() {
  local force_install=false

  # Check if yq exists and can parse basic YAML
  if command -v yq >/dev/null 2>&1; then
    # Test if yq can actually parse YAML correctly
    local test_yaml="/tmp/yq_test_$$.yaml"
    cat > "$test_yaml" << 'EOF'
test:
  - item1
  - item2
required:
  - shell-essential
  - core-development
EOF

    local test_result
    # Use the installed yq if available, otherwise fall back to PATH version
    local yq_cmd="/usr/local/bin/yq"
    if [ ! -x "$yq_cmd" ]; then
      yq_cmd="yq"
    fi
    test_result=$("$yq_cmd" eval '.required[]' "$test_yaml" 2>/dev/null || echo "")
    rm -f "$test_yaml"

    if [ -z "$test_result" ] || [ "$test_result" = "null" ]; then
      ui_action_warning "Found yq, but it cannot parse YAML correctly. Forcing reinstall from GitHub."
      force_install=true
    else
      local version_lines
      version_lines=$(echo "$test_result" | wc -l)
      if [ "$version_lines" -lt 2 ]; then
        ui_action_warning "Found yq, but it doesn't parse arrays correctly. Forcing reinstall from GitHub."
        force_install=true
      else
        ui_verbose_info "⇒ yq is working correctly."
        return 0
      fi
    fi
  else
    ui_action_warning "yq not found. Installing from GitHub."
    force_install=true
  fi

  if [ "$force_install" = "true" ]; then
    _install_yq_from_github
  fi
}

_install_yq_from_github() {
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
      aarch64) dry_run_arch="arm64" ;;
      arm64) dry_run_arch="arm64" ;;
      armv7l) dry_run_arch="arm" ;;
      *) dry_run_arch="unknown_arch" ;;
    esac

    local dry_run_bin_name="yq_${dry_run_os}_${dry_run_arch}"
    local dry_run_url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${dry_run_bin_name}"
    local dry_run_tmpbin="/tmp/yq_${dry_run_os}_${dry_run_arch}_${YQ_VERSION}.tmp"
    local dry_run_dest="/usr/local/bin/yq"

    dry_run_command_ui_info "curl -fsSL \"$dry_run_url\" -o \"$dry_run_tmpbin\""
    dry_run_command_ui_info "sudo mv \"$dry_run_tmpbin\" \"$dry_run_dest\" && sudo chmod +x \"$dry_run_dest\""
    return 0
  fi

  ui_action_start "$(_f "Installing yq v%s from GitHub..." "$YQ_VERSION")"

  # Remove any existing yq installations to avoid conflicts
  if [ -f "/usr/local/bin/yq" ]; then
    ui_verbose_info "Removing existing yq installation"
    sudo rm -f "/usr/local/bin/yq" 2>/dev/null || true
  fi

  # Also try to remove from other common locations
  sudo rm -f "/usr/bin/yq" 2>/dev/null || true
  sudo rm -f "/bin/yq" 2>/dev/null || true

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
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
    *)
      ui_action_error "$(_f "Unsupported architecture: %s. Cannot install yq." "$(uname -m)")"
      return 1
      ;;
  esac

  BIN_NAME="yq_${OS}_${ARCH}"
  URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BIN_NAME}"
  DEST="/usr/local/bin/yq"
  TMPBIN="/tmp/yq_${OS}_${ARCH}_${YQ_VERSION}.tmp"

  ui_verbose_info "$(_f "Attempting to download yq from: %s" "$URL")"

  if curl -fsSL "$URL" -o "$TMPBIN"; then
    ui_verbose_info "$(_f "Downloaded yq to temporary location: %s" "$TMPBIN")"
    if sudo mv "$TMPBIN" "$DEST"; then
      if sudo chmod +x "$DEST"; then
        ui_action_success "$(_f "yq v%s successfully installed to %s." "$YQ_VERSION" "$DEST")"

        # Verify the installation works
        local test_yaml="/tmp/yq_verify_$$.yaml"
        cat > "$test_yaml" << 'EOF'
test:
  - item1
  - item2
EOF

        local verify_result
        verify_result=$("$DEST" eval '.test[]' "$test_yaml" 2>/dev/null || echo "")
        rm -f "$test_yaml"

        if [ -z "$verify_result" ]; then
          ui_action_error "yq installation verification failed - cannot parse YAML"
          return 1
        fi

        ui_verbose_info "yq installation verified successfully"
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
