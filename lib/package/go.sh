#!/usr/bin/env bash

# lib/package/go.sh - Go package management

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/common.sh"

GO_PACKAGES_DIR="${MEOW}/packages/go"

# Check if go package is installed (by binary name)
go_is_installed() {
  local package_name="$1"
  local binary_name
  binary_name=$(basename "$package_name" | sed 's/@.*//')
  command -v "$binary_name" &>/dev/null
}

# Install go packages
install_go_packages() {
  install_packages_generic "$1" "$2" "go" "Gofile" "go install" "go_is_installed"
}

# Update go packages
update_go_packages() {
  update_packages_generic "$1" "$2" "go" "Gofile" "go install" "go_is_installed" "(go: installing executables|go: no module dependencies)"
}

# Set up go
setup_go() {
  local indent="${1:-0}"

  if ! command -v go &>/dev/null; then
    step_header "$indent" "Setting up Go"

    indented_warning "$indent" "Go is not installed. This should be handled by homebrew packages."
    indented_info "$indent" "Please install Go via homebrew or your system package manager."
    indented_info "$indent" "After installing Go, ensure GOPATH and GOBIN are properly configured."
    return 1
  fi

  success_tick_msg "$indent" "Go is available"

  local gobin_path
  if [[ -n "${GOBIN:-}" ]]; then
    gobin_path="$GOBIN"
  elif [[ -n "${GOPATH:-}" ]]; then
    gobin_path="$GOPATH/bin"
  else
    gobin_path="$(go env GOPATH)/bin"
  fi

  if [[ ":$PATH:" == *":$gobin_path:"* ]]; then
    success_tick_msg "$indent" "Go binary path ($gobin_path) is in PATH"
  else
    indented_warning "$indent" "Go binary path ($gobin_path) is not in PATH"
    indented_info "$indent" "Add 'export PATH=\"$gobin_path:\$PATH\"' to your shell profile"
  fi

  return 0
}