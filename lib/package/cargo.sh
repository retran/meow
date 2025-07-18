#!/usr/bin/env bash

# lib/package/cargo.sh - Functions for managing cargo packages

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_CARGO_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_CARGO_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

CARGO_PACKAGES_DIR="${DOTFILES_DIR}/packages/cargo"

install_cargo_packages() {
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

  step_header "$indent_level" "Cargo Packages ($category)"
  action_msg "$indent_level" "Verifying and installing cargo packages for category: $category"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all cargo package categories..."
    local overall_success=true
    for cargofile_path in "$CARGO_PACKAGES_DIR"/*.Cargofile; do
      if [[ -f "$cargofile_path" ]]; then
        local current_category
        current_category=$(basename "$cargofile_path" .Cargofile)
        if ! install_cargo_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All cargo package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some cargo package categories encountered issues."
      return 1
    fi
  fi

  local cargofile="${CARGO_PACKAGES_DIR}/${category}.Cargofile"
  if [[ ! -f "$cargofile" ]]; then
    indented_error_msg "$indent_level" "Cargofile not found: $cargofile"
    return 1
  fi

  if ! command -v cargo &>/dev/null; then
    indented_error_msg "$indent_level" "Cargo is not installed or not in PATH"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    package_name=$(echo "$line" | awk '{print $1}')

    # Check if package is already installed
    if cargo install --list 2>/dev/null | grep -q "^${package_name} "; then
      local verify_status
      run_package_operation "$((indent_level+1))" "$package_name" "verify" \
        "Verifying $package_name installation" \
        "Successfully verified $package_name." \
        "Failed to verify $package_name." \
        "$package_name is already correctly installed." \
        --pattern "(already installed|Installing)" \
        cargo install "$package_name" --force
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
        cargo install "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$cargofile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -gt 0 ]]; then
    indented_warning "$indent_level" "Cargo packages processed with $failed_count error(s) in ${duration}s."
  else
    success_tick_msg "$indent_level" "Cargo packages processed successfully in ${duration}s."
  fi

  if [[ $installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Installed $installed_count package(s): ${installed_packages[*]}"
  fi
  if [[ $already_installed_count -gt 0 ]]; then
    indented_info "$((indent_level+1))" "Already installed $already_installed_count package(s): ${already_installed_packages[*]}"
  fi

  return 0
}

update_cargo_packages() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local upgraded_packages_list=()
  local verified_packages_list=()
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Updating Cargo Packages ($category)"

  if ! command -v cargo &>/dev/null; then
    info_italic_msg "$indent_level" "Cargo not available, skipping cargo package updates"
    return 100
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all Cargofile categories..."
    local overall_success=true
    for cargofile_path in "$CARGO_PACKAGES_DIR"/*.Cargofile; do
      if [[ -f "$cargofile_path" ]]; then
        local current_category
        current_category=$(basename "$cargofile_path" .Cargofile)
        if ! update_cargo_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All cargo package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some cargo package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local cargofile="${CARGO_PACKAGES_DIR}/${category}.Cargofile"

  if [[ ! -f "$cargofile" ]]; then
    indented_error_msg "$indent_level" "Cargofile not found: $cargofile"
    return 1
  fi

  action_msg "$((indent_level+1))" "Checking for updates in category: $category"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $1}')

    if cargo install --list 2>/dev/null | grep -q "^${package_name} "; then
      local upgrade_status
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Updating $package_name" \
        "Successfully updated $package_name." \
        "Failed to update $package_name." \
        "$package_name is already up to date." \
        --pattern "(already installed|Installing)" \
        cargo install "$package_name" --force
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
  done < "$cargofile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "Cargo packages for '$category' updated successfully ($packages_upgraded_count updated, $packages_verified_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All cargo packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Some cargo packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
}

setup_cargo() {
  local indent="${1:-0}"

  if ! command -v cargo &>/dev/null; then
    step_header "$indent" "Setting up Cargo"

    indented_warning "$indent" "Cargo is not installed. This should be handled by homebrew packages."
    indented_info "$indent" "Please install Rust via rustup or your system package manager."
    indented_info "$indent" "After installing Rust, ensure cargo binary path is properly configured."
    return 1
  fi

  success_tick_msg "$indent" "Cargo is available"

  local cargo_bin_path
  cargo_bin_path="$HOME/.cargo/bin"

  if [[ ":$PATH:" == *":$cargo_bin_path:"* ]]; then
    success_tick_msg "$indent" "Cargo binary path ($cargo_bin_path) is in PATH"
  else
    indented_warning "$indent" "Cargo binary path ($cargo_bin_path) is not in PATH"
    indented_info "$indent" "Add 'export PATH=\"$cargo_bin_path:\$PATH\"' to your shell profile"
  fi

  return 0
}