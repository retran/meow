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
        --pattern "(up to date|already installed)" \
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
        "$package_name is already installed." \
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

update_npm_packages() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local upgraded_packages_list=()
  local verified_packages_list=()
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Updating npm Packages ($category)"

  if ! command -v npm &>/dev/null; then
    indented_warning "$((indent_level+1))" "npm not installed. Skipping update."
    return 1
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all npmfile categories..."
    local overall_success=true
    for npmfile_path in "$NPM_PACKAGES_DIR"/*.npmfile; do
      if [[ -f "$npmfile_path" ]]; then
        local current_category
        current_category=$(basename "$npmfile_path" .npmfile)
        if ! update_npm_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All npm package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some npm package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local npmfile="${NPM_PACKAGES_DIR}/${category}.npmfile"

  if [[ ! -f "$npmfile" ]]; then
    indented_error_msg "$indent_level" "Npmfile not found: $npmfile"
    return 1
  fi

  action_msg "$((indent_level+1))" "Checking for outdated packages in category: $category"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $1}')

    if npm list -g --depth=0 "$package_name" &>/dev/null; then
      local upgrade_status
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Checking for updates to $package_name" \
        "Successfully upgraded $package_name." \
        "Failed to upgrade $package_name." \
        "$package_name is already up to date." \
        --pattern "(up to date|already at the latest version)" \
        npm update -g "$package_name"
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
  done < "$npmfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "npm packages for '$category' updated successfully ($packages_upgraded_count upgraded, $packages_verified_count up-to-date) (${duration}s)"
    else
      success_tick_msg "$indent_level" "All npm packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
    fi
    return 0
  else
    indented_error_msg "$indent_level" "Some npm packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
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

