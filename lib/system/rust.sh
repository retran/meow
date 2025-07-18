#!/usr/bin/env bash

# lib/system/rust.sh - Rust setup functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

setup_rustup() {
  local indent_level="$1"
  
  step_header "$indent_level" "Setting up Rust toolchain"
  
  # Check if rustup-init is available (should be installed via homebrew)
  if ! command -v rustup-init >/dev/null 2>&1; then
    indented_warning "$indent_level" "rustup-init not found. Please ensure rustup-init is installed via homebrew."
    return 1
  fi
  
  # Check if rustup is already initialized
  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      success_tick_msg "$indent_level" "Rust toolchain already initialized"
      return 0
    fi
  fi
  
  action_msg "$indent_level" "Initializing Rust toolchain with rustup..."
  
  # Initialize rustup with default stable toolchain
  # Use -y flag to accept defaults and avoid interactive prompts
  if rustup-init -y --default-toolchain stable --no-modify-path >/dev/null 2>&1; then
    success_tick_msg "$indent_level" "Rust toolchain initialized successfully"
    
    # Ensure rustup/cargo are available in current session
    if [[ -f "$HOME/.cargo/env" ]]; then
      # shellcheck source=/dev/null
      source "$HOME/.cargo/env"
    fi
    
    # Verify installation
    if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
      local rust_version
      rust_version=$(rustc --version 2>/dev/null || echo "unknown")
      indented_info "$((indent_level + 1))" "Rust version: $rust_version"
      success_tick_msg "$indent_level" "Rust toolchain setup complete"
    else
      indented_warning "$indent_level" "Rust toolchain initialized but commands not available in current session"
      indented_info "$((indent_level + 1))" "Please restart your shell or source ~/.cargo/env"
    fi
  else
    indented_error_msg "$indent_level" "Failed to initialize Rust toolchain"
    return 1
  fi
}