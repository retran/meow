#!/usr/bin/env bash

# lib/package/go.sh - Functions for managing global Go packages

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_GO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_GO_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

GO_PACKAGES_DIR="${DOTFILES_DIR}/packages/go"

install_go_packages() {
  local category="$1"
  local indent_level="${2:-1}"
  local package_name
  local installed_count=0
  local already_installed_count=0
  local failed_count=0
  local start_time end_time duration
  local installed_packages=()
  local already_installed_packages=()

  start_time=$(date +%s)

  step_header "$indent_level" "Global Go Packages ($category)"
  action_msg "$indent_level" "Verifying and installing Go packages for category: $category"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all Go package categories..."
    local overall_success=true
    for gofile_path in "$GO_PACKAGES_DIR"/*.Gofile; do
      if [[ -f "$gofile_path" ]]; then
        local current_category
        current_category=$(basename "$gofile_path" .Gofile)
        if ! install_go_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All Go package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some Go package categories encountered issues."
      return 1
    fi
  fi

  local gofile="${GO_PACKAGES_DIR}/${category}.Gofile"
  if [[ ! -f "$gofile" ]]; then
    indented_error_msg "$indent_level" "Gofile not found: $gofile"
    return 1
  fi

  # Check if Go is available
  if ! command -v go &>/dev/null; then
    indented_error_msg "$indent_level" "Go is not installed or not in PATH"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    package_name=$(echo "$line" | awk '{print $1}')

    # Extract the binary name from the package path for checking installation
    local binary_name
    binary_name=$(basename "$package_name" | sed 's/@.*//')
    
    # Check if package binary is already available in PATH
    if command -v "$binary_name" &>/dev/null; then
      local verify_status
      run_package_operation "$((indent_level+1))" "$package_name" "verify" \
        "Verifying $package_name installation" \
        "Successfully verified $package_name." \
        "Failed to verify $package_name." \
        "$package_name is already correctly installed." \
        --pattern "(go: installing executables|go: no module dependencies)" \
        go install "$package_name"
      verify_status=$?

      if [ $verify_status -eq 0 ] || [ $verify_status -eq 100 ]; then
        already_installed_packages+=("$package_name")
        already_installed_count=$((already_installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    else
      local install_status
      run_package_operation "$((indent_level+1))" "$package_name" "install" \
        "Installing $package_name" \
        "Successfully installed $package_name." \
        "Failed to install $package_name." \
        "$package_name is already installed." \
        go install "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$gofile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -gt 0 ]]; then
    indented_warning "$indent_level" "Go packages processed with $failed_count error(s) in ${duration}s."
  else
    success_tick_msg "$indent_level" "Go packages processed successfully in ${duration}s."
  fi

  if [[ $installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Installed $installed_count package(s): ${installed_packages[*]}"
  fi
  if [[ $already_installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Already installed $already_installed_count package(s): ${already_installed_packages[*]}"
  fi

  return 0
}

update_go_packages() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local upgraded_packages_list=()
  local verified_packages_list=()
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Updating Go Packages ($category)"

  if ! command -v go &>/dev/null; then
    indented_warning "$((indent_level+1))" "Go not installed. Skipping update."
    return 1
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all Gofile categories..."
    local overall_success=true
    for gofile_path in "$GO_PACKAGES_DIR"/*.Gofile; do
      if [[ -f "$gofile_path" ]]; then
        local current_category
        current_category=$(basename "$gofile_path" .Gofile)
        if ! update_go_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All Go package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some Go package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local gofile="${GO_PACKAGES_DIR}/${category}.Gofile"

  if [[ ! -f "$gofile" ]]; then
    indented_error_msg "$indent_level" "Gofile not found: $gofile"
    return 1
  fi

  action_msg "$((indent_level+1))" "Checking for updates in category: $category"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $1}')

    # Extract the binary name from the package path for checking installation
    local binary_name
    binary_name=$(basename "$package_name" | sed 's/@.*//')

    if command -v "$binary_name" &>/dev/null; then
      local upgrade_status
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Updating $package_name" \
        "Successfully updated $package_name." \
        "Failed to update $package_name." \
        "$package_name is already up to date." \
        --pattern "(go: installing executables|go: no module dependencies)" \
        go install "$package_name"
      upgrade_status=$?

      if [ $upgrade_status -eq 0 ]; then
        upgraded_packages_list+=("$package_name")
        packages_upgraded_count=$((packages_upgraded_count + 1))
      elif [ $upgrade_status -eq 100 ]; then
        verified_packages_list+=("$package_name")
        packages_verified_count=$((packages_verified_count + 1))
      else
        packages_failed_count=$((packages_failed_count + 1))
      fi
    else
      info_italic_msg "$((indent_level+1))" "$package_name not installed, skipping"
    fi
  done < "$gofile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "Go packages for '$category' updated successfully ($packages_upgraded_count updated, $packages_verified_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All Go packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Some Go packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
}

# Helper function to check if Go is available and set up if needed
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
  
  # Check if GOBIN is set and in PATH
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