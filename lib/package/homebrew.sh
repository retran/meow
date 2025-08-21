#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_HOMEBREW_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_HOMEBREW_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_brew_packages() {
  cache_package_list "brew" "brew list --formula -1 2>/dev/null; brew list --cask -1 2>/dev/null"
}

is_homebrew_package_installed() {
  _cache_installed_brew_packages
  is_package_installed "brew" "$1"
}

setup_homebrew() {
  step_header "Setting up Homebrew"
  command -v brew >/dev/null 2>&1 || {
    warning "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
      {
        error_msg "Homebrew installation failed"
        return 1
      }
    eval "$("$(brew --prefix)"/bin/brew shellenv)"
  }
  success_tick_msg "Homebrew available"
}

install_homebrew_packages() {
  install_packages_generic "$1" "homebrew" "brew install" "is_homebrew_package_installed"
}

update_homebrew_packages() {
  update_packages_generic "$1" "homebrew" "brew upgrade" "is_homebrew_package_installed" \
    "(already installed|latest version is already installed)"
}

cleanup_homebrew() {
  step_header "Cleaning Homebrew"
  ui_spinner "Pruning Homebrew" \
    --success "Homebrew cache cleaned" \
    --fail "Homebrew cleanup failed" \
    brew cleanup --prune=all
}
