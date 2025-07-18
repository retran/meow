#!/usr/bin/env bash

# lib/package/pipx.sh - Functions for managing Python packages with pipx

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

PIPX_PACKAGES_DIR="${DOTFILES_DIR}/packages/pipx"

install_pipx_packages() {
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

  step_header "$indent_level" "Python Packages ($category)"
  action_msg "$indent_level" "Verifying and installing pipx packages for category: $category"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all Pipxfile categories..."
    local overall_success=true
    for pipxfile_path in "$PIPX_PACKAGES_DIR"/*.Pipxfile; do
      if [[ -f "$pipxfile_path" ]]; then
        local current_category
        current_category=$(basename "$pipxfile_path" .Pipxfile)
        if ! install_pipx_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All pipx package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some pipx package categories encountered issues."
      return 1
    fi
  fi

  local pipxfile="${PIPX_PACKAGES_DIR}/${category}.Pipxfile"
  if [[ ! -f "$pipxfile" ]]; then
    indented_error_msg "$indent_level" "Pipxfile not found: $pipxfile"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    package_name=$(echo "$line" | awk '{print $1}')

    if pipx list --short | grep -q "^${package_name} "; then
      local verify_status
      run_package_operation "$((indent_level+1))" "$package_name" "verify" \
        "Verifying $package_name installation" \
        "Successfully verified $package_name." \
        "Failed to verify $package_name." \
        "$package_name is already correctly installed." \
        pipx install "$package_name"
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
        "Installing $package_name with pipx" \
        "Successfully installed $package_name." \
        "Failed to install $package_name." \
        "$package_name is already installed." \
        pipx install "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$pipxfile"

  local total_processed=$((installed_count + already_installed_count))
  indented_info "$((indent_level+1))" "($total_processed packages processed: $installed_count new, $already_installed_count existing)"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  success_tick_msg "$indent_level" "Pipx packages for '$category' processed (${duration}s)"

  if [[ $failed_count -eq 0 ]]; then
    return 0
  else
    indented_error_msg "$indent_level" "Some pipx packages for '$category' failed ($failed_count failures)"
    return 1
  fi
}

update_pipx_packages() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local upgraded_packages_list=()
  local verified_packages_list=()
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Updating pipx Packages ($category)"

  if ! command -v pipx &>/dev/null; then
    info_italic_msg "$indent_level" "pipx not available, skipping pipx package updates"
    return 100
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all Pipxfile categories..."
    local overall_success=true
    for pipxfile_path in "$PIPX_PACKAGES_DIR"/*.Pipxfile; do
      if [[ -f "$pipxfile_path" ]]; then
        local current_category
        current_category=$(basename "$pipxfile_path" .Pipxfile)
        if ! update_pipx_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All pipx package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some pipx package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local pipxfile="${PIPX_PACKAGES_DIR}/${category}.Pipxfile"

  if [[ ! -f "$pipxfile" ]]; then
    indented_error_msg "$indent_level" "Pipxfile not found: $pipxfile"
    return 1
  fi

  action_msg "$((indent_level+1))" "Checking for outdated packages in category: $category"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $1}')

    if pipx list --short | grep -q "^${package_name} "; then
      local upgrade_status
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Checking for updates to $package_name" \
        "Successfully upgraded $package_name." \
        "Failed to upgrade $package_name." \
        "$package_name is already up to date." \
        pipx upgrade "$package_name"
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
  done < "$pipxfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "Pipx packages for '$category' updated successfully ($packages_upgraded_count upgraded, $packages_verified_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All pipx packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Some pipx packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
}
