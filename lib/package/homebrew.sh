#!/usr/bin/env bash

# Include guard to prevent multiple sourcing.
if [ -n "${_LIB_PACKAGE_HOMEBREW_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_HOMEBREW_SOURCED=1

set -o pipefail 2>/dev/null || :

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_brew_packages() {
  cache_package_list "brew" "brew list --formula -1 2>/dev/null; brew list --cask -1 2>/dev/null"
}

is_homebrew_package_installed() {
  _cache_installed_brew_packages
  is_package_installed "brew" "$1"
}

setup_homebrew() {
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_setup "Homebrew"
  fi

  if is_dry_run; then
    if ! command -v brew >/dev/null 2>&1; then
      dry_run_ui_info "Homebrew is not installed. Would install Homebrew using its official script."
      dry_run_ui_info "  Script URL: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
      dry_run_ui_info "  Would configure shell environment after installation."
    else
      dry_run_ui_info "Homebrew is already installed. No setup needed."
    fi
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1; then
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_warning "Homebrew not found. Starting installation..."
      if ! ui_spinner "Installing Homebrew..." \
        --success "Homebrew installed successfully." \
        --fail "Homebrew installation failed." \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        return 1
      fi
    else
      if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1; then
        return 1
      fi
    fi
    eval "$("$(brew --prefix)"/bin/brew shellenv)" 2>/dev/null
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_ready "Homebrew"
  fi
}

install_homebrew_packages() {
  install_packages_generic "$1" "homebrew" "brew install" "is_homebrew_package_installed"
}

update_homebrew_packages() {
  update_packages_generic "$1" "homebrew" "brew upgrade" "is_homebrew_package_installed" \
    "(already installed|latest version is already installed)"
}

uninstall_homebrew_packages() {
  uninstall_packages_generic "$1" "homebrew" "brew uninstall" "is_homebrew_package_installed"
}

cleanup_homebrew() {
  if is_dry_run; then
    dry_run_ui_info "Would perform Homebrew cleanup (cache and unused packages)."
    dry_run_ui_info "  Command: brew cleanup --prune=all"
    dry_run_ui_info "  This command removes outdated downloads and old package versions."
    return 0
  fi

  ui_spinner "Cleaning Homebrew cache and old versions..." \
    --success "Homebrew cleaned successfully." \
    --fail "Homebrew cleanup failed." \
    brew cleanup --prune=all
}
