#!/usr/bin/env bash

# lib/package/npm.sh - Functions for managing global npm packages

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_NPM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_NPM_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

NPM_PACKAGES_DIR="${DOTFILES_DIR}/packages/npm"

install_npm_packages() {
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

  step_header "$indent_level" "Global npm Packages ($category)"
  action_msg "$indent_level" "Verifying and installing global npm packages for category: $category"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all npm package categories..."
    local overall_success=true
    for npmfile_path in "$NPM_PACKAGES_DIR"/*.npmfile; do
      if [[ -f "$npmfile_path" ]]; then
        local current_category
        current_category=$(basename "$npmfile_path" .npmfile)
        if ! install_npm_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All npm package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some npm package categories encountered issues."
      return 1
    fi
  fi

  local npmfile="${NPM_PACKAGES_DIR}/${category}.npmfile"
  if [[ ! -f "$npmfile" ]]; then
    indented_error_msg "$indent_level" "Npmfile not found: $npmfile"
    return 1
  fi

  # Check if npm is available
  if ! command -v npm &>/dev/null; then
    indented_error_msg "$indent_level" "npm is not installed or not in PATH"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    package_name=$(echo "$line" | awk '{print $1}')

    # Check if package is already installed globally
    if npm list -g --depth=0 "$package_name" &>/dev/null; then
      local verify_status
      run_package_operation "$((indent_level+1))" "$package_name" "verify" \
        "Verifying $package_name installation" \
        "Successfully verified $package_name." \
        "Failed to verify $package_name." \
        "$package_name is already correctly installed." \
        npm install -g "$package_name"
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
        "" \
        npm install -g "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$npmfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -gt 0 ]]; then
    indented_warning "$indent_level" "npm packages processed with $failed_count error(s) in ${duration}s."
  else
    success_tick_msg "$indent_level" "npm packages processed successfully in ${duration}s."
  fi

  if [[ $installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Installed $installed_count package(s): ${installed_packages[*]}"
  fi
  if [[ $already_installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Already installed $already_installed_count package(s): ${already_installed_packages[*]}"
  fi

  return 0
}

# Helper function to check if npm is available and set up if needed
setup_npm() {
  local indent="${1:-0}"
  
  if ! command -v npm &>/dev/null; then
    step_header "$indent" "Setting up npm"
    
    if command -v node &>/dev/null; then
      indented_warning "$indent" "Node.js is available but npm is not found in PATH"
      return 1
    else
      indented_warning "$indent" "Node.js and npm are not installed. This should be handled by homebrew packages."
      return 1
    fi
  fi
  
  success_tick_msg "$indent" "npm is available"
  return 0
}

# Function to run package operations with consistent error handling
run_package_operation() {
  local indent_level="$1"
  local package_name="$2"
  local operation="$3"
  local action_message="$4"
  local success_message="$5"
  local error_message="$6"
  local skip_message="$7"
  shift 7
  local command=("$@")

  action_msg "$indent_level" "$action_message"

  if [[ -n "$skip_message" && "$operation" == "verify" ]]; then
    indented_info "$((indent_level+1))" "$skip_message"
    return 100  # Special exit code for "already installed"
  fi

  local output
  local exit_code
  
  # Capture both stdout and stderr
  output=$("${command[@]}" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    success_tick_msg "$((indent_level+1))" "$success_message"
    return 0
  else
    indented_error_msg "$((indent_level+1))" "$error_message"
    if [[ -n "$output" ]]; then
      # Only show the first few lines of error output to avoid spam
      echo "$output" | head -3 | while IFS= read -r line; do
        indented_error_msg "$((indent_level+2))" "$line"
      done
    fi
    return 1
  fi
}