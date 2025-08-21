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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Setting up Homebrew"
  fi

  command -v brew >/dev/null 2>&1 || {
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      warning "Homebrew not found. Installing..."
      ui_spinner "Installing Homebrew" \
        --success "Homebrew installed successfully" \
        --fail "Homebrew installation failed" \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
    fi

    if [[ $? -ne 0 ]]; then
      return 1
    fi
    eval "$("$(brew --prefix)"/bin/brew shellenv)" 2>/dev/null
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    success_tick_msg "Homebrew available"
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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cleaning Homebrew"
    ui_spinner "Pruning cache and unused packages" \
      --success "Homebrew cleanup completed" \
      --fail "Homebrew cleanup failed" \
      brew cleanup --prune=all
  else
    ui_spinner "Cleaning Homebrew" \
      --success "Homebrew cleanup completed" \
      --fail "Homebrew cleanup failed" \
      brew cleanup --prune=all
  fi
}
