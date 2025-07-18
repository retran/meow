#!/usr/bin/env bash

# lib/package/common.sh - Common package manager functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_COMMON_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_COMMON_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

# Generic install packages function
# Usage: install_packages <category> <indent_level> <package_type> <file_extension> <install_cmd> <list_check_cmd> [package_name_transform]
install_packages_generic() {
  local category="$1"
  local indent_level="${2:-1}"
  local package_type="$3"
  local file_extension="$4"
  local install_cmd="$5"
  local list_check_cmd="$6"
  local name_transform="${7:-cat}"
  
  local package_name
  local installed_count=0
  local already_installed_count=0
  local failed_count=0
  local start_time end_time duration
  local installed_packages=()
  local already_installed_packages=()

  start_time=$(date +%s)
  
  # Get package directory variable
  local package_dir_var="${package_type^^}_PACKAGES_DIR"
  local package_dir
  eval "package_dir=\$$package_dir_var"
  
  step_header "$indent_level" "${package_type^} Packages ($category)"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all ${package_type} package categories..."
    local overall_success=true
    for package_file in "$package_dir"/*."$file_extension"; do
      if [[ -f "$package_file" ]]; then
        local current_category
        current_category=$(basename "$package_file" ".$file_extension")
        if ! install_packages_generic "$current_category" "$((indent_level+1))" "$package_type" "$file_extension" "$install_cmd" "$list_check_cmd" "$name_transform"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All ${package_type} package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some ${package_type} package categories encountered issues."
      return 1
    fi
  fi

  local package_file="${package_dir}/${category}.${file_extension}"
  if [[ ! -f "$package_file" ]]; then
    indented_error_msg "$indent_level" "${package_type^}file not found: $package_file"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    package_name=$(echo "$line" | awk '{print $1}')

    if eval "$list_check_cmd \"\$package_name\"" &>/dev/null; then
      already_installed_packages+=("$package_name")
      already_installed_count=$((already_installed_count + 1))
    else
      local install_status
      run_package_operation "$((indent_level+1))" "$package_name" "install" \
        "Installing $package_name" \
        "Successfully installed $package_name." \
        "Failed to install $package_name." \
        "$package_name is already installed." \
        $install_cmd "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$package_file"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "${package_type^} packages processed successfully in ${duration}s."
    return 0
  else
    indented_warning "$indent_level" "${package_type^} packages processed with $failed_count error(s) in ${duration}s."
    return 1
  fi
}

# Generic update packages function
# Usage: update_packages_generic <category> <indent_level> <package_type> <file_extension> <update_cmd> <list_check_cmd> [unchanged_pattern]
update_packages_generic() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local package_type="$3"
  local file_extension="$4"
  local update_cmd="$5"
  local list_check_cmd="$6"
  local unchanged_pattern="${7:-}"
  
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local start_time end_time duration

  start_time=$(date +%s)
  
  # Get package directory variable
  local package_dir_var="${package_type^^}_PACKAGES_DIR"
  local package_dir
  eval "package_dir=\$$package_dir_var"
  
  step_header "$indent_level" "Updating ${package_type^} Packages ($category)"

  # Check if command is available
  local cmd_name
  cmd_name=$(echo "$update_cmd" | awk '{print $1}')
  if ! command -v "$cmd_name" &>/dev/null; then
    info_italic_msg "$indent_level" "${package_type^} not available, skipping ${package_type} package updates"
    return 100
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all ${package_type}file categories..."
    local overall_success=true
    for package_file in "$package_dir"/*."$file_extension"; do
      if [[ -f "$package_file" ]]; then
        local current_category
        current_category=$(basename "$package_file" ".$file_extension")
        if ! update_packages_generic "$current_category" "$((indent_level+1))" "$package_type" "$file_extension" "$update_cmd" "$list_check_cmd" "$unchanged_pattern"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All ${package_type} package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some ${package_type} package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local package_file="${package_dir}/${category}.${file_extension}"
  
  if [[ ! -f "$package_file" ]]; then
    indented_error_msg "$indent_level" "${package_type^}file not found: $package_file"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $1}')

    if eval "$list_check_cmd \"\$package_name\"" &>/dev/null; then
      local upgrade_status
      local upgrade_args=()
      if [[ -n "$unchanged_pattern" ]]; then
        upgrade_args+=(--pattern "$unchanged_pattern")
      fi
      
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Checking for updates to $package_name" \
        "Successfully upgraded $package_name." \
        "Failed to upgrade $package_name." \
        "$package_name is already up to date." \
        "${upgrade_args[@]}" \
        $update_cmd "$package_name"
      upgrade_status=$?

      if [ $upgrade_status -eq 0 ]; then
        packages_upgraded_count=$((packages_upgraded_count + 1))
      elif [ $upgrade_status -eq 100 ]; then
        packages_verified_count=$((packages_verified_count + 1))
      else
        packages_failed_count=$((packages_failed_count + 1))
      fi
    else
      info_italic_msg "$((indent_level+1))" "$package_name not installed, skipping"
    fi
  done < "$package_file"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "${package_type^} packages for '$category' updated successfully ($packages_upgraded_count upgraded, $packages_verified_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All ${package_type} packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Some ${package_type} packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
}