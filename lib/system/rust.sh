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
  
  # Check if rustup is already installed and configured
  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      success_tick_msg "$indent_level" "Rust toolchain already initialized"
      # Still run component installation in case they're missing
      install_rust_components "$indent_level"
      return 0
    fi
  fi
  
  action_msg "$indent_level" "Installing Rust toolchain with rustup..."
  
  # Install Rust using rustup default stable
  if rustup default stable >/dev/null 2>&1; then
    success_tick_msg "$indent_level" "Rust toolchain installed successfully"
    
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
      
      # Install essential components
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
  
  # Install clippy (linter)
  if rustup component add clippy >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "clippy installed"
  else
    indented_warning "$((indent_level + 1))" "Failed to install clippy component"
  fi
  
  # Install rust-analyzer (LSP server)
  if rustup component add rust-analyzer >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "rust-analyzer installed"
  else
    indented_warning "$((indent_level + 1))" "Failed to install rust-analyzer component"
  fi
  
  # rustfmt is included by default with Rust, just verify it's available
  if command -v rustfmt >/dev/null 2>&1; then
    success_tick_msg "$((indent_level + 1))" "rustfmt available"
  else
    indented_warning "$((indent_level + 1))" "rustfmt not available"
  fi
}