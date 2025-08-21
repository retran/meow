#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

source "${MEOW}/lib/package/common.sh"

is_go_package_installed() {
  local pkg="$1"
  local bin
  bin="$(basename "$pkg" | sed 's/@.*//')"
  command -v "$bin" >/dev/null 2>&1
}

setup_go() {
  step_header "Setting up Go"
  command -v go >/dev/null 2>&1 || {
    error_msg "Go not found"
    return 1
  }
  success_tick_msg "Go available"
}

install_go_packages() {
  install_packages_generic "$1" "go" "go install" "is_go_package_installed"
}

update_go_packages() {
  update_packages_generic "$1" "go" "go install" "is_go_package_installed" \
    "(go: installing executables|go: no module dependencies)"
}

uninstall_go_packages() {
  step_header "Go Package Removal ($1)"
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/go.list"
  if [[ -f "$package_file" ]]; then
    warning "Go packages cannot be automatically uninstalled via go command"
    info "Go packages are installed to GOPATH/bin. Please manually remove binaries if needed:"

    # Try to get GOPATH, but handle the case where go is not available
    local go_bin_path=""
    if command -v go >/dev/null 2>&1; then
      go_bin_path="$(go env GOPATH)/bin"
    else
      # Fallback to default GOPATH if go command is not available
      go_bin_path="${GOPATH:-$HOME/go}/bin"
    fi

    while IFS= read -r line; do
      local package_name
      package_name=$(parse_package_line "$line")
      [[ -z "$package_name" ]] && continue
      local bin
      bin="$(basename "$package_name" | sed 's/@.*//')"
      local binary_path="$go_bin_path/$bin"
      if [[ -f "$binary_path" ]]; then
        info "  rm \"$binary_path\""
      fi
    done <"$package_file"
  fi
  return 0
}
