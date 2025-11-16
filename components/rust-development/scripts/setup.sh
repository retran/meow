#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/rust-development/scripts/setup.sh
# @brief: Setup script for Rust development environment and toolchain installation.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"

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

  if command -v rustfmt >/dev/null 2>&1; then
    ui_action_success "rustfmt available."
  else
    ui_info "rustfmt not available or not in PATH."
  fi
}

# Setup rustup with verbose and dry-run support
if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Setting up rustup for component: $COMPONENT_NAME"
fi

if [ "$MEOW_DRY_RUN" = "true" ]; then
  echo "DRY-RUN: Would setup rustup for component: $COMPONENT_NAME"
else
  setup_rustup || true
fi
