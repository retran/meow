#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The exit status of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully.

# Source the UI library for consistent messaging.
# MEOW environment variable is expected to be set for the path to be valid.
source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Rust Development cleanup..."

# Check if cargo is installed and callable.
if command -v cargo >/dev/null 2>&1; then
  ui_info "  📦 Cleaning cargo cache..."
  # Clean cargo's build cache and registry.
  # Redirect stderr to /dev/null and continue on error.
  cargo cache --autoclean 2>/dev/null || true

  ui_info "  🗑️  Cleaning cargo registry cache..."
  # Remove the cargo registry cache directory if it exists.
  # Redirect stderr to /dev/null and continue on error.
  if [[ -d "$HOME/.cargo/registry" ]]; then
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
  fi

  ui_info "  🗑️  Cleaning cargo git cache..."
  # Remove the cargo git checkouts directory if it exists.
  # Redirect stderr to /dev/null and continue on error.
  if [[ -d "$HOME/.cargo/git" ]]; then
    rm -rf "$HOME/.cargo/git/checkouts" 2>/dev/null || true
  fi
fi

ui_info "  🗑️  Cleaning Rust target directories..."
# Find and remove all 'target' directories under the user's home directory.
# The -path "*/Cargo.toml" -prune part in the original script is kept for
# preserving original logic, although it likely has no effect as a directory
# named "target" will not match the path pattern "*/Cargo.toml".
# Redirect stderr to /dev/null and continue on error.
find "$HOME" -name "target" -type d -path "*/Cargo.toml" -prune -o -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

# Check if rustup's temporary directory exists.
if [[ -d "$HOME/.rustup/tmp" ]]; then
  ui_info "  🗑️  Cleaning rustup temporary files..."
  # Remove rustup's temporary directory if it exists.
  # Redirect stderr to /dev/null and continue on error.
  rm -rf "$HOME/.rustup/tmp" 2>/dev/null || true
fi

ui_success "✅ Rust Development cleanup completed"
