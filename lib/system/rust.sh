#!/usr/bin/env bash

# lib/system/rust.sh - Rust setup functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

setup_rustup() {
  local indent_level="$1"

  step_header "$indent_level" "Setting up Rust toolchain"

  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      success_tick_msg "$indent_level" "Rust toolchain already initialized"
      install_rust_components "$indent_level"
      return 0
    fi
  fi

  action_msg "$indent_level" "Installing Rust toolchain with rustup..."

  if rustup default stable >/dev/null 2>&1; then
    success_tick_msg "$indent_level" "Rust toolchain installed successfully"

    if [[ -f "$HOME/.cargo/env" ]]; then
      source "$HOME/.cargo/env"
    fi

    if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
      local rust_version
      rust_version=$(rustc --version 2>/dev/null || echo "unknown")
      indented_info "$((indent_level + 1))" "Rust version: $rust_version"

      install_rust_components "$indent_level"

      success_tick_msg "$indent_level" "Rust toolchain setup complete"
    else
      indented_warning "$indent_level" "Rust toolchain installed but commands not available in current session"
      indented_info "$((indent_level + 1))" "Please restart your shell or source ~/.cargo/env"
    fi
  else
    indented_error_msg "$indent_level" "Failed to install Rust toolchain"
    return 1
  fi
}

install_rust_components() {
  local indent_level="$1"

  action_msg "$indent_level" "Installing Rust components..."

  if rustup component add clippy >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "clippy installed"
  else
    indented_warning "$((indent_level + 1))" "Failed to install clippy component"
  fi

  if rustup component add rust-analyzer >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "rust-analyzer installed"
  else
    indented_warning "$((indent_level + 1))" "Failed to install rust-analyzer component"
  fi

  if command -v rustfmt >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "rustfmt available"
  else
    indented_warning "$((indent_level + 1))" "rustfmt not available"
  fi
}
