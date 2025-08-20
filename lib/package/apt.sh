#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"

APT_PACKAGES_DIR="${MEOW}/packages/apt"

_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\\n' -W 2>/dev/null"
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

setup_apt() {
  step_header "Setting up APT"

  command -v apt-get >/dev/null 2>&1 || {
    error_msg "apt-get not found"
    return 1
  }

  ui_spinner "Updating APT index" \
    --success "APT index updated" \
    --fail "Failed to update APT index" \
    sudo apt-get update
}

install_apt_packages() {
  install_packages_generic "$1" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

update_apt_packages() {
  update_packages_generic "$1" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

cleanup_apt() {
  step_header "Cleaning APT"
  ui_spinner "Autoremove unused packages" \
    --success "APT autoremove done" \
    --fail "APT autoremove failed" \
    sudo apt-get autoremove -y
  ui_spinner "Cleaning APT cache" \
    --success "APT cache cleaned" \
    --fail "APT cache cleanup failed" \
    sudo apt-get clean
}
