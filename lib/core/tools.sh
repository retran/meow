#!/usr/bin/env bash

if [ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

# Detect operating system using POSIX-compliant uname
_detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "darwin" ;;
    *) echo "unknown" ;;
  esac
}

# Detect CPU architecture using POSIX-compliant uname
_detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64) echo "arm64" ;;
    armv7l) echo "arm" ;;
    *) echo "unknown" ;;
  esac
}

# Get installation directory with fallback
_get_install_dir() {
  if [ -w "/usr/local/bin" ] 2>/dev/null; then
    echo "/usr/local/bin"
  elif [ -w "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    echo "$HOME/.local/bin"
  else
    echo ""
  fi
}

ensure_yq() {
  local force_install=false

  # Check if yq exists and can parse basic YAML
  if command -v yq >/dev/null 2>&1; then
    # Test if yq can actually parse YAML correctly
    local test_yaml="/tmp/yq_test_$$.yaml"
    cat >"$test_yaml" <<'EOF'
test:
  - item1
  - item2
required:
  - shell-essential
  - development-essential
EOF

    local test_result
    test_result=$(yq eval '.required[]' "$test_yaml" 2>/dev/null || echo "")
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
  local OS ARCH INSTALL_DIR

  # Detect environment using helper functions
  OS=$(_detect_os)
  ARCH=$(_detect_arch)
  INSTALL_DIR=$(_get_install_dir)

  # Validate detected environment
  if [ "$OS" = "unknown" ]; then
    ui_action_error "$(_f "Unsupported OS: %s. Cannot install yq." "$(uname -s)")"
    return 1
  fi

  if [ "$ARCH" = "unknown" ]; then
    ui_action_error "$(_f "Unsupported architecture: %s. Cannot install yq." "$(uname -m)")"
    return 1
  fi

  if [ -z "$INSTALL_DIR" ]; then
    ui_action_error "Cannot find writable directory for yq installation. Tried /usr/local/bin and \$HOME/.local/bin"
    return 1
  fi

  local BIN_NAME URL DEST TMPBIN use_sudo
  BIN_NAME="yq_${OS}_${ARCH}"
  URL="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BIN_NAME}"
  DEST="${INSTALL_DIR}/yq"
  TMPBIN="/tmp/yq_${OS}_${ARCH}_${YQ_VERSION}.tmp"

  # Determine if we need sudo based on install directory
  use_sudo="false"
  if [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
    use_sudo="true"
  fi

  if is_dry_run; then
    dry_run_ui_info "Would install yq v${YQ_VERSION} to ${DEST}."
    dry_run_command_ui_info "curl -fsSL \"$URL\" -o \"$TMPBIN\""
    if [ "$use_sudo" = true ]; then
      dry_run_command_ui_info "sudo mv \"$TMPBIN\" \"$DEST\" && sudo chmod +x \"$DEST\""
    else
      dry_run_command_ui_info "mv \"$TMPBIN\" \"$DEST\" && chmod +x \"$DEST\""
    fi
    return 0
  fi

  ui_action_start "$(_f "Installing yq v%s to %s..." "$YQ_VERSION" "$DEST")"

  # Remove any existing yq installations to avoid conflicts
  if [ -f "$DEST" ]; then
    ui_verbose_info "Removing existing yq installation from $DEST"
    if [ "$use_sudo" = true ]; then
      sudo rm -f "$DEST" 2>/dev/null || true
    else
      rm -f "$DEST" 2>/dev/null || true
    fi
  fi

  ui_verbose_info "$(_f "Downloading yq from: %s" "$URL")"

  # Download yq binary
  if ! curl -fsSL "$URL" -o "$TMPBIN"; then
    ui_action_error "$(_f "Failed to download yq from %s. Please check your network connection." "$URL")"
    return 1
  fi

  ui_verbose_info "$(_f "Downloaded yq to temporary location: %s" "$TMPBIN")"

  # Move to destination and make executable
  if [ "$use_sudo" = true ]; then
    if ! sudo mv "$TMPBIN" "$DEST"; then
      ui_action_error "$(_f "Failed to move yq binary to %s." "$DEST")"
      rm -f "$TMPBIN" 2>/dev/null || true
      return 1
    fi
    if ! sudo chmod +x "$DEST"; then
      ui_action_error "$(_f "Failed to make yq executable at %s." "$DEST")"
      return 1
    fi
  else
    if ! mv "$TMPBIN" "$DEST"; then
      ui_action_error "$(_f "Failed to move yq binary to %s." "$DEST")"
      rm -f "$TMPBIN" 2>/dev/null || true
      return 1
    fi
    if ! chmod +x "$DEST"; then
      ui_action_error "$(_f "Failed to make yq executable at %s." "$DEST")"
      return 1
    fi
  fi

  ui_action_success "$(_f "yq v%s successfully installed to %s." "$YQ_VERSION" "$DEST")"

  # Verify the installation works
  local test_yaml="/tmp/yq_verify_$$.yaml"
  cat >"$test_yaml" <<'EOF'
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

  local expected_lines
  expected_lines=$(echo "$verify_result" | wc -l)
  if [ "$expected_lines" -lt 2 ]; then
    ui_action_error "yq installation verification failed - incorrect output"
    return 1
  fi

  ui_verbose_info "yq installation verified successfully"

  # Add to PATH if installing to ~/.local/bin
  if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
    ui_verbose_info "yq installed to ~/.local/bin - ensure this directory is in your PATH"
  fi

  return 0
}
