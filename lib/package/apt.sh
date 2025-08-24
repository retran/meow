#!/usr/bin/env bash

# Guard to prevent multiple sourcing of this file.
if [ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

# Caches the list of installed APT packages using dpkg-query.
_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\\n' -W 2>/dev/null"
}

# Checks if a specific APT package is installed.
# Arguments:
#   $1 - The name of the package to check.
is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

# Sets up the APT package manager (e.g., updates package index).
setup_apt() {
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_setup "APT"
  fi

  if is_dry_run; then
    dry_run_ui_info "APT: Would check for 'apt-get' command."
    if ! command -v apt-get >/dev/null 2>&1; then
      dry_run_ui_info "APT: 'apt-get' command not found. APT setup would fail."
    else
      dry_run_ui_info "APT: Would update package index to refresh available package information."
      dry_run_ui_info "  Command: sudo apt-get update"
    fi
    return 0
  fi

  command -v apt-get >/dev/null 2>&1 || {
    ui_error "APT: 'apt-get' command not found. Cannot set up APT."
    return 1
  }

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_spinner "APT: Updating package index" \
      --success "APT: Package index updated successfully." \
      --fail "APT: Failed to update package index." \
      sudo apt-get update
  else
    sudo apt-get update >/dev/null 2>&1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_ready "APT"
  fi
}

# Installs APT packages.
# Arguments:
#   $1 - A space-separated string of package names to install.
install_apt_packages() {
  install_packages_generic "$1" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

# Updates APT packages.
# Arguments:
#   $1 - A space-separated string of package names to update.
update_apt_packages() {
  update_packages_generic "$1" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

# Uninstalls APT packages.
# Arguments:
#   $1 - A space-separated string of package names to uninstall.
uninstall_apt_packages() {
  uninstall_packages_generic "$1" "apt" "sudo apt-get remove -y" "is_apt_package_installed"
}

# Cleans up the APT environment (e.g., removes unused packages, clears cache).
cleanup_apt() {
  if is_dry_run; then
    dry_run_ui_info "APT: Would remove orphaned packages and clear the download cache."
    dry_run_ui_info "  Commands: sudo apt-get autoremove -y && sudo apt-get clean"
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_package_manager_cleaning "APT"

    ui_spinner "APT: Removing unused packages" \
      --success "APT: Unused packages removed successfully." \
      --fail "APT: Failed to remove unused packages." \
      sudo apt-get autoremove -y

    ui_spinner "APT: Cleaning package cache" \
      --success "APT: Package cache cleaned successfully." \
      --fail "APT: Failed to clean package cache." \
      sudo apt-get clean
  else
    ui_spinner "APT: Cleaning environment" \
      --success "APT: Environment cleaned successfully." \
      --fail "APT: Failed to clean APT environment." \
      bash -c "sudo apt-get autoremove -y && sudo apt-get clean"
  fi
}
