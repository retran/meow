#!/usr/bin/env bash

# lib/package/apt.sh - APT package management (Debian-based)

if [[ -n "${_LIB_PACKAGE_APT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_APT_SOURCED=1

source "${MEOW}/lib/package/common.sh"

APT_PACKAGES_DIR="${MEOW}/packages/apt"

_cache_installed_apt_packages() {
  if [[ -z "${_APT_INSTALLED_PACKAGES:-}" ]]; then
    action_msg "${1:-0}" "Caching APT package list..."
    _APT_INSTALLED_PACKAGES="$(dpkg-query -f='${binary:Package}\n' -W 2>/dev/null)"
  fi
}

is_apt_package_installed() {
  _cache_installed_apt_packages
  grep -qE "^$1$" <<<"$_APT_INSTALLED_PACKAGES"
}

setup_apt() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up APT"

  command -v apt-get >/dev/null 2>&1 || {
    indented_error_msg "$indent" "apt-get not found"
    return 1
  }

  # Initial APT index update
  ui_spinner "$((indent + 1))" "Updating APT index" \
    --success "APT index updated" \
    --fail "Failed to update APT index" \
    sudo apt-get update

  # Ensure we have the latest yq (v4+) from the community PPA
  if ! grep -Rq "rmescandon/yq" /etc/apt/sources.list /etc/apt/sources.list.d; then
    ui_spinner "$((indent + 1))" "Adding yq PPA" \
      --success "yq PPA added" \
      --fail "Failed to add yq PPA" \
      bash -c "sudo apt-get install -y software-properties-common && sudo add-apt-repository -y ppa:rmescandon/yq"
    ui_spinner "$((indent + 1))" "Updating APT index after adding yq PPA" \
      --success "APT index updated with yq PPA" \
      --fail "Failed to update APT index after yq PPA" \
      sudo apt-get update
  fi
}

install_apt_packages() {
  install_packages_generic "$1" "$2" "apt" "sudo apt-get install -y" "is_apt_package_installed"
}

update_apt_packages() {
  update_packages_generic "$1" "$2" "apt" "sudo apt-get install --only-upgrade -y" \
    "is_apt_package_installed" "(is already the newest version|not upgraded)"
}

cleanup_apt() {
  local indent="${1:-0}"
  step_header "$indent" "Cleaning APT"
  ui_spinner "$((indent + 1))" "Autoremove unused packages" \
    --success "APT autoremove done" \
    --fail "APT autoremove failed" \
    sudo apt-get autoremove -y
  ui_spinner "$((indent + 1))" "Cleaning APT cache" \
    --success "APT cache cleaned" \
    --fail "APT cache cleanup failed" \
    sudo apt-get clean
}
