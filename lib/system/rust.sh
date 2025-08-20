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

  action_msg "Installing Rust toolchain with rustup..."

  if rustup default stable >/dev/null 2>&1; then
    success_tick_msg "Rust toolchain installed successfully"

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
  else
    error_msg "Failed to install Rust toolchain"
    return 1
  fi
}

install_rust_components() {
  action_msg "Installing Rust components..."

  if rustup component add clippy >/dev/null 2>&1; then
    success_tick_msg "clippy installed"
  else
    warning "Failed to install clippy component"
  fi

  if rustup component add rust-analyzer >/dev/null 2>&1; then
    success_tick_msg "rust-analyzer installed"
  else
    warning "Failed to install rust-analyzer component"
  fi

  if command -v rustfmt >/dev/null 2>&1; then
    success_tick_msg "rustfmt available"
  else
    warning "rustfmt not available"
  fi
}
