#!/usr/bin/env bash

# lib/package/homebrew.sh - Homebrew package management

if [[ -n "${_LIB_PACKAGE_HOMEBREW_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_HOMEBREW_SOURCED=1

source "${MEOW}/lib/package/common.sh"

HOMEBREW_PACKAGES_DIR="${MEOW}/packages/homebrew"

_cache_installed_brew_packages() {
  if [[ -z "${_BREW_INSTALLED_PACKAGES:-}" ]]; then
    action_msg "${1:-0}" "Caching Homebrew package list..."
    _BREW_INSTALLED_PACKAGES="$(
      brew list --formula -1 2>/dev/null
      brew list --cask   -1 2>/dev/null
    )"
  fi
}

is_homebrew_package_installed() {
  _cache_installed_brew_packages
  grep -qE "^$1$" <<< "$_BREW_INSTALLED_PACKAGES"
}

setup_homebrew() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up Homebrew"
  command -v brew >/dev/null 2>&1 || {
    indented_warning "$indent" "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || { indented_error_msg "$indent" "Homebrew installation failed"; return 1; }
    eval "$($(brew --prefix)/bin/brew shellenv)"
  }
  success_tick_msg "$indent" "Homebrew available"
}

install_homebrew_packages() {
  install_packages_generic "$1" "$2" "homebrew" "brew install" "is_homebrew_package_installed"
}

update_homebrew_packages() {
  update_packages_generic "$1" "$2" "homebrew" "brew upgrade" "is_homebrew_package_installed" \
    "(already installed|latest version is already installed)"
}

cleanup_homebrew() {
  local indent="${1:-0}"
  step_header "$indent" "Cleaning Homebrew"
  ui_spinner "$((indent + 1))" "Pruning Homebrew" \
    --success "Homebrew cache cleaned" \
    --fail    "Homebrew cleanup failed" \
    brew cleanup --prune=all
}

