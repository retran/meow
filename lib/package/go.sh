#!/usr/bin/env bash

# Enable strict mode:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: The return value of a pipeline is the status of the last command
#              to exit with a non-zero status, or zero if all commands exit
#              successfully.

# Source UI utilities for consistent messaging.
source "${MEOW}/lib/core/ui.sh"

# Ensure this script is sourced only once.
if [ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

# Source common package management functions and dry-run utilities.
source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

# is_go_package_installed checks if a Go package's binary is available in PATH.
# Arguments:
#   $1: The Go package name (e.g., "github.com/cli/cli/cmd/gh@latest")
# Returns:
#   0 if the package's binary is found, 1 otherwise.
is_go_package_installed() {
  local pkg="$1"
  local bin
  # Extract the binary name from the package path, removing version suffixes.
  # Example: "github.com/cli/cli/cmd/gh@latest" -> "gh"
  bin="$(basename "$pkg" | sed 's/@.*//')"
  command -v "$bin" >/dev/null 2>&1
}

# setup_go ensures the Go command is available.
# Returns:
#   0 on success, 1 if Go command is not found.
setup_go() {
  ui_step_header "Setting up Go"

  if is_dry_run; then
    if ! command -v go >/dev/null 2>&1; then
      dry_run_ui_info "Go is not found in PATH. Setup would fail without the 'go' command."
    else
      dry_run_ui_info "Go is already available. Ready for package installation."
    fi
    return 0
  fi

  if ! command -v go >/dev/null 2>&1; then
    ui_action_error "Go command not found in PATH."
    return 1
  else
    ui_action_success "Go command available."
  fi
}

# install_go_packages installs Go packages listed in a component's package file.
# Arguments:
#   $1: The component name.
install_go_packages() {
  install_packages_generic "$1" "go" "go install" "is_go_package_installed"
}

# update_go_packages updates Go packages listed in a component's package file.
# Arguments:
#   $1: The component name.
update_go_packages() {
  # The regex captures common successful installation messages from 'go install'.
  update_packages_generic "$1" "go" "go install" "is_go_package_installed" \
    "(go: installing executables|go: no module dependencies)"
}

# uninstall_go_packages handles the removal of Go packages.
# Note: Go does not provide a direct uninstall command. This function
# provides guidance for manual removal.
# Arguments:
#   $1: The component name.
uninstall_go_packages() {
  ui_step_header "$(_f "Go Package Removal (%s)" "$1")"
  local package_file="${MEOW_COMPONENTS_DIR}/$1/packages/go.list"

  if [ -f "$package_file" ]; then
    ui_warning "Go packages cannot be automatically uninstalled via the 'go' command."
    ui_info "Go packages are typically installed to GOPATH/bin. Please manually remove the binaries if needed:"

    local go_bin_path=""
    if command -v go >/dev/null 2>&1; then
      go_bin_path="$(go env GOPATH)/bin"
    else
      # Fallback to default GOPATH if 'go' command is not available.
      go_bin_path="${GOPATH:-$HOME/go}/bin"
    fi

    # Read each package line from the file.
    while IFS= read -r line; do
      local package_name
      # parse_package_line is assumed to be defined in common.sh
      package_name=$(parse_package_line "$line")
      # Skip empty lines or comments.
      [ -z "$package_name" ] && continue

      local bin
      # Extract the binary name from the package path.
      bin="$(basename "$package_name" | sed 's/@.*//')"
      local binary_path="$go_bin_path/$bin"

      # Inform the user about the potential binary location.
      if [ -f "$binary_path" ]; then
        ui_info "  Would consider removing: \"$binary_path\""
      fi
    done <"$package_file"
  else
    ui_info "No Go package list found for component '$1'."
  fi
  return 0
}

# cleanup_go handles Go-specific cleanup tasks.
# Note: Go typically manages its own caches automatically.
cleanup_go() {
  if is_dry_run; then
    dry_run_ui_info "Go cleanup would be skipped (no explicit cleanup mechanism needed)."
    dry_run_ui_info "  Go modules are cached in GOMODCACHE, which Go manages automatically."
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "Cleaning Go (no-operation)"
  fi
  ui_action_success "Go cleanup skipped; Go manages its own caches automatically."
}
