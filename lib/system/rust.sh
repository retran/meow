#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

if [ "${BASH_SOURCE[0]}" != "${0}" ] && [ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

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
    ui_error "Failed to install Rust toolchain."
    return 1
  fi

  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  fi

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

install_rust_components() {
  ui_step_header "Installing Rust components"

  if ! ui_spinner "Installing clippy component" \
    --success "clippy installed successfully." \
    --fail "Failed to install clippy component." \
    rustup component add clippy; then
    ui_error "Failed to install clippy component."
  fi

  if ! ui_spinner "Installing rust-analyzer component" \
    --success "rust-analyzer installed successfully." \
    --fail "Failed to install rust-analyzer component." \
    rustup component add rust-analyzer; then
    ui_error "Failed to install rust-analyzer component."
  fi

  if command -v rustfmt >/dev/null 2>&1; then
    ui_action_success "rustfmt available."
  else
    ui_info "rustfmt not available or not in PATH."
  fi
}
