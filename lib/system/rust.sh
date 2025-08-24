#!/usr/bin/env bash

# This script expects MEOW to be set, pointing to the dotfiles repository root.
# Example: export MEOW="$HOME/.dotfiles"

# Source UI functions for consistent output.
source "${MEOW}/lib/core/ui.sh"

# Prevent sourcing the script multiple times within the same shell session.
if [ "${BASH_SOURCE[0]}" != "${0}" ] && [ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

# setup_rustup initializes or verifies the Rust toolchain installation.
setup_rustup() {
  ui_step_header "Setting up Rust toolchain"

  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      ui_action_success "Rust toolchain already initialized."
      install_rust_components
      return 0
    fi
  fi

  if ! ui_spinner "Installing Rust toolchain with rustup" \
    --success "Rust toolchain installed successfully." \
    --fail "Failed to install Rust toolchain." \
    rustup default stable; then
    return 1
  fi

  # Source cargo environment variables if the file exists.
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
  fi

  # Verify Rust installation after sourcing environment.
  if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    local rust_version
    rust_version=$(rustc --version 2>/dev/null || echo "unknown")
    ui_info "$(_f "Rust version: %s" "$rust_version")"

    install_rust_components

    ui_action_success "Rust toolchain setup complete."
  else
    ui_warning "Rust toolchain installed but commands not available in current session."
    ui_info "Please restart your shell or source ~/.cargo/env manually."
  fi
}

# install_rust_components installs common Rust development tools.
install_rust_components() {
  ui_step_header "Installing Rust components"

  ui_spinner "Installing clippy component" \
    --success "clippy installed successfully." \
    --fail "Failed to install clippy component." \
    rustup component add clippy || true # Continue if component fails to install

  ui_spinner "Installing rust-analyzer component" \
    --success "rust-analyzer installed successfully." \
    --fail "Failed to install rust-analyzer component." \
    rustup component add rust-analyzer || true # Continue if component fails to install

  if command -v rustfmt >/dev/null 2>&1; then
    ui_action_success "rustfmt available."
  else
    ui_info "rustfmt not available or not in PATH."
  fi
}
