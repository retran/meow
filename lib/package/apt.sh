#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"

_cache_installed_apt_packages() {
  cache_package_list "apt" "dpkg-query -f='\${binary:Package}\\n' -W 2>/dev/null"
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  is_package_installed "apt" "$1"
}

setup_apt() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Setting up APT"
  fi

  command -v apt-get >/dev/null 2>&1 || {
    return 1
  }

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_spinner "Updating APT index" \
      --success "APT index updated" \
      --fail "Failed to update APT index" \
      sudo apt-get update
  else
    sudo apt-get update >/dev/null 2>&1
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    success_tick_msg "APT ready"
  fi
}

install_apt_packages() {
  install_packages_generic "$1" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

update_apt_packages() {
  update_packages_generic "$1" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

uninstall_apt_packages() {
  uninstall_packages_generic "$1" "apt" "sudo apt-get remove -y" "is_apt_package_installed"
}

cleanup_apt() {
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cleaning APT"
    ui_spinner "Removing unused packages" \
      --success "APT autoremove completed" \
      --fail "APT autoremove failed" \
      sudo apt-get autoremove -y
    ui_spinner "Cleaning cache" \
      --success "APT cleanup completed" \
      --fail "APT cleanup failed" \
      sudo apt-get clean
  else
    ui_spinner "Cleaning APT" \
      --success "APT cleanup completed" \
      --fail "APT cleanup failed" \
      bash -c "sudo apt-get autoremove -y && sudo apt-get clean"
  fi
}
