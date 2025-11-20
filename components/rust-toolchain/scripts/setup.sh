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
# @file: components/rust-toolchain/scripts/setup.sh
# @brief: Installs rustup/rust toolchain before cargo packages run.
# @author: Andrew Vasilyev
# @license: MIT
#
set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"

install_rustup_cli() {
  if command -v rustup >/dev/null 2>&1; then
    return 0
  fi

  ui_step_header "Installing rustup"

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would download and run the official rustup installer script."
    return 0
  fi

  local installer_cmd=""
  if command -v curl >/dev/null 2>&1; then
    installer_cmd="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs"
  elif command -v wget >/dev/null 2>&1; then
    installer_cmd="wget -qO- https://sh.rustup.rs"
  else
    ui_error "Neither curl nor wget is available to download the rustup installer."
    return 1
  fi

  if ! eval "$installer_cmd" | sh -s -- -y --no-modify-path; then
    ui_error "Failed to run the rustup installer."
    return 1
  fi

  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
  else
    export PATH="$HOME/.cargo/bin:${PATH}"
  fi

  mkdir -p "$HOME/.local/bin"
  if [ -x "$HOME/.cargo/bin/cargo" ]; then
    ln -sf "$HOME/.cargo/bin/cargo" "$HOME/.local/bin/cargo"
  fi
  if [ -x "$HOME/.cargo/bin/rustup" ]; then
    ln -sf "$HOME/.cargo/bin/rustup" "$HOME/.local/bin/rustup"
  fi

  ui_action_success "rustup installed successfully."
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

setup_rustup() {
  if ! command -v rustup >/dev/null 2>&1; then
    install_rustup_cli || return 1
  fi

  ui_step_header "Ensuring Rust toolchain is installed"

  if rustup show >/dev/null 2>&1; then
    ui_action_success "Rust toolchain already initialized."
    install_rust_components
    return 0
  fi

  if ! ui_spinner "Installing Rust toolchain with rustup" \
    --success "Rust toolchain installed successfully." \
    --fail "Failed to install Rust toolchain." \
    rustup default stable; then
    ui_error "Failed to install Rust toolchain."
    return 1
  fi

  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
  fi

  install_rust_components

  if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    local rust_version
    rust_version=$(rustc --version 2>/dev/null || echo "unknown")
    ui_info "$(_f "Rust version: %s" "$rust_version")"
    ui_action_success "Rust toolchain setup complete."
  else
    ui_warning "Rust toolchain installed but commands not available in current session."
    ui_info "Please restart your shell or source ~/.cargo/env manually."
  fi
}

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "Setting up rustup for component '${COMPONENT_NAME}'."
fi

if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
  ui_info "DRY-RUN: Would setup rustup for component '${COMPONENT_NAME}'."
else
  setup_rustup || true
fi
