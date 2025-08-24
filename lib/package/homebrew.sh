#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_HOMEBREW_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_HOMEBREW_SOURCED=1

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
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_package_manager_setup "Homebrew"
  fi

  if is_dry_run; then
    if ! command -v brew >/dev/null 2>&1; then
      dry_run_ui_info "$(fmt "homebrew_would_install")"
      dry_run_ui_info "  $(fmt "homebrew_install_script_url")"
      dry_run_ui_info "  $(fmt "homebrew_would_configure")"
    else
      dry_run_ui_info "$(fmt "homebrew_already_available")"
    fi
    return 0
  fi

  command -v brew >/dev/null 2>&1 || {
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      ui_warning "$(fmt 'homebrew_not_found')"
      parse_spinner_messages "homebrew_install" >/dev/null
      ui_spinner "$SPINNER_PROGRESS" \
        --success "$SPINNER_SUCCESS" \
        --fail "$SPINNER_FAIL" \
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
    dry_run_ui_info "$(fmt "homebrew_would_clean_cache")"
    dry_run_ui_info "  $(fmt "homebrew_cleanup_command")"
    dry_run_ui_info "  $(fmt "homebrew_would_remove_outdated")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_package_manager_cleaning "Homebrew"
    parse_spinner_messages "homebrew_prune" >/dev/null
    ui_spinner "$SPINNER_PROGRESS" \
      --success "$SPINNER_SUCCESS" \
      --fail "$SPINNER_FAIL" \
      brew cleanup --prune=all
  else
    parse_spinner_messages "homebrew_cleanup" >/dev/null
    ui_spinner "$SPINNER_PROGRESS" \
      --success "$SPINNER_SUCCESS" \
      --fail "$SPINNER_FAIL" \
      brew cleanup --prune=all
  fi
}
