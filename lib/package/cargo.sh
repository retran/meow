#!/usr/bin/env bash

# lib/package/cargo.sh - Cargo package management

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/common.sh"

CARGO_PACKAGES_DIR="${MEOW}/packages/cargo"

# Check if cargo package is installed
cargo_is_installed() {
  local package_name="$1"
  cargo install --list 2>/dev/null | grep -q "^${package_name} "
}

# Install cargo packages
install_cargo_packages() {
  install_packages_generic "$1" "$2" "cargo" "Cargofile" "cargo install" "cargo_is_installed"
}

# Update cargo packages
update_cargo_packages() {
  update_packages_generic "$1" "$2" "cargo" "Cargofile" "cargo install --force" "cargo_is_installed" "(already installed|Installing)"
}

# Set up cargo
setup_cargo() {
  local indent="${1:-0}"

  if ! command -v cargo >/dev/null 2>&1; then
    step_header "$indent" "Setting up Cargo"

    indented_warning "$indent" "Cargo is not installed. This should be handled by homebrew packages."
    indented_info "$indent" "Please install Rust via rustup or your system package manager."
    indented_info "$indent" "After installing Rust, ensure cargo binary path is properly configured."
    return 1
  fi

  success_tick_msg "$indent" "Cargo is available"

  local cargo_bin_path
  cargo_bin_path="$HOME/.cargo/bin"

  if [[ ":$PATH:" == *":$cargo_bin_path:"* ]]; then
    success_tick_msg "$indent" "Cargo binary path ($cargo_bin_path) is in PATH"
  else
    indented_warning "$indent" "Cargo binary path ($cargo_bin_path) is not in PATH"
    indented_info "$indent" "Add 'export PATH=\"$cargo_bin_path:\$PATH\"' to your shell profile"
  fi

  return 0
}
