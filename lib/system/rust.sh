#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_rustup() {
  step_header "Setting up Rust toolchain"

  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      success_tick_msg "Rust toolchain already initialized"
      install_rust_components
      return 0
    fi
  fi

  ui_spinner "Installing Rust toolchain with rustup" \
    --success "Rust toolchain installed successfully" \
    --fail "Failed to install Rust toolchain" \
    rustup default stable

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
  fi

  if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    local rust_version
    rust_version=$(rustc --version 2>/dev/null || echo "unknown")
    info "Rust version: $rust_version"

    install_rust_components

    success_tick_msg "Rust toolchain setup complete"
  else
    warning "Rust toolchain installed but commands not available in current session"
    info "Please restart your shell or source ~/.cargo/env"
  fi
}

install_rust_components() {
  step_header "Installing Rust components"

  ui_spinner "Installing clippy component" \
    --success "clippy installed" \
    --fail "Failed to install clippy component" \
    rustup component add clippy

  ui_spinner "Installing rust-analyzer component" \
    --success "rust-analyzer installed" \
    --fail "Failed to install rust-analyzer component" \
    rustup component add rust-analyzer

  if command -v rustfmt >/dev/null 2>&1; then
    success_tick_msg "rustfmt available"
  else
    warning "rustfmt not available"
  fi
}
