#!/usr/bin/env bash

# lib/package/mas.sh - Mac App Store package management functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_MAS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_MAS_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

MAS_PACKAGES_DIR="${DOTFILES_DIR}/packages/mas"

is_mas_app_installed() {
  local app_id="$1"
  mas list | grep -q "^${app_id}"
}

install_mas_packages() {
  local category="$1"
  local indent_level="${2:-1}"
  local app_name app_id
  local installed_count=0
  local already_installed_count=0
  local failed_count=0
  local start_time end_time duration
  local installed_packages=()
  local already_installed_packages=()

  start_time=$(date +%s)

  step_header "$indent_level" "Mac App Store Applications ($category)"

  if ! command -v mas &>/dev/null; then
    indented_error_msg "$indent_level" "mas (Mac App Store CLI) is required but not installed."
    indented_info "$((indent_level+1))" "Install it with: brew install mas"
    return 1
  fi

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all Masfile categories..."
    local overall_success=true
    for masfile_path in "$MAS_PACKAGES_DIR"/*.Masfile; do
      if [[ -f "$masfile_path" ]]; then
        local current_category
        current_category=$(basename "$masfile_path" .Masfile)
        if ! install_mas_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All mas package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some mas package categories encountered issues."
      return 1
    fi
  fi

  local masfile="${MAS_PACKAGES_DIR}/${category}.Masfile"
  if [[ ! -f "$masfile" ]]; then
    info_italic_msg "$indent_level" "No Mac App Store applications defined for category: $category"
    return 0
  fi

  action_msg "$indent_level" "Verifying and installing Mac App Store applications for category: $category"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^\".*\"[[:space:]]+id:[[:space:]]+[0-9]+$ ]]; then
      # Extract app name (bash 3.2 compatible)
      local temp=${line#*\"}  # Remove up to first quote
      app_name=${temp%\"*}   # Remove from last quote to end
      
      # Extract app ID (bash 3.2 compatible)  
      local temp2=${line##*id: }  # Remove everything up to "id: "
      app_id=${temp2}

      if is_mas_app_installed "$app_id"; then
        info_italic_msg "$((indent_level+1))" "$app_name already installed, skipping"
        already_installed_packages+=("$app_name")
        ((already_installed_count++))
      else
        action_msg "$((indent_level+1))" "Installing $app_name (ID: $app_id)..."
        local install_output
        install_output=$(mas install "$app_id" 2>&1)
        local install_exit_code=$?

        if [[ $install_exit_code -eq 0 ]]; then
          success_tick_msg "$((indent_level+1))" "$app_name installed successfully"
          installed_packages+=("$app_name")
          ((installed_count++))
        else
          if echo "$install_output" | grep -q "Not signed in"; then
            indented_error_msg "$((indent_level+1))" "Failed to install $app_name: Not signed in to Mac App Store"
            indented_info "$((indent_level+2))" "Please sign in through the App Store app and try again"
          else
            indented_error_msg "$((indent_level+1))" "Failed to install $app_name (ID: $app_id)"
            if [[ -n "$install_output" ]]; then
              indented_info "$((indent_level+2))" "Error: $install_output"
            fi
          fi
          ((failed_count++))
        fi
      fi
    else
      indented_warning "$((indent_level+1))" "Invalid format in Masfile: $line"
    fi
  done < "$masfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $installed_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "Mac App Store applications for '$category' installed successfully ($installed_count installed, $already_installed_count already installed) (${duration}s)"
  elif [[ $installed_count -eq 0 && $already_installed_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "All Mac App Store applications for '$category' are already installed ($already_installed_count packages) (${duration}s)"
  elif [[ $failed_count -gt 0 ]]; then
    indented_error_msg "$indent_level" "Mac App Store installation for '$category' completed with errors ($installed_count installed, $failed_count failed) (${duration}s)"
    return 1
  else
    success_tick_msg "$indent_level" "No Mac App Store applications to install for '$category' (${duration}s)"
  fi

  return 0
}

update_mas_packages() {
  local category="$1"
  local indent_level="${2:-1}"
  local app_name app_id
  local updated_count=0
  local up_to_date_count=0
  local failed_count=0
  local start_time end_time duration

  start_time=$(date +%s)

  step_header "$indent_level" "Updating Mac App Store Applications ($category)"

  if ! command -v mas &>/dev/null; then
    info_italic_msg "$indent_level" "mas not available, skipping Mac App Store updates"
    return 100
  fi

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all Masfile categories..."
    local overall_success=true
    for masfile_path in "$MAS_PACKAGES_DIR"/*.Masfile; do
      if [[ -f "$masfile_path" ]]; then
        local current_category
        current_category=$(basename "$masfile_path" .Masfile)
        if ! update_mas_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All mas package categories updated successfully."
      return 0
    else
      indented_warning "$indent_level" "Some mas package categories encountered issues during update."
      return 1
    fi
  fi

  local masfile="${MAS_PACKAGES_DIR}/${category}.Masfile"
  if [[ ! -f "$masfile" ]]; then
    info_italic_msg "$indent_level" "No Mac App Store applications defined for category: $category"
    return 0
  fi

  action_msg "$indent_level" "Checking for outdated packages in category: $category"

  local outdated_apps
  outdated_apps=$(mas outdated 2>/dev/null)

  if [[ -z "$outdated_apps" ]]; then
    info_italic_msg "$((indent_level+1))" "No Mac App Store apps need updates"
    success_tick_msg "$indent_level" "All Mac App Store applications for '$category' are up-to-date (0 packages)"
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^\".*\"[[:space:]]+id:[[:space:]]+[0-9]+$ ]]; then
      # Extract app name (bash 3.2 compatible)
      local temp=${line#*\"}  # Remove up to first quote
      app_name=${temp%\"*}   # Remove from last quote to end
      
      # Extract app ID (bash 3.2 compatible)  
      local temp2=${line##*id: }  # Remove everything up to "id: "
      app_id=${temp2}

      if ! is_mas_app_installed "$app_id"; then
        info_italic_msg "$((indent_level+1))" "$app_name not installed, skipping"
        continue
      fi

      if echo "$outdated_apps" | grep -q "^$app_id "; then
        action_msg "$((indent_level+1))" "Upgrading $app_name..."
        local upgrade_output
        upgrade_output=$(mas upgrade "$app_id" 2>&1)
        local upgrade_exit_code=$?

        if [[ $upgrade_exit_code -eq 0 ]]; then
          success_tick_msg "$((indent_level+1))" "Successfully upgraded $app_name."
          ((updated_count++))
        else
          if echo "$upgrade_output" | grep -q "Not signed in"; then
            indented_error_msg "$((indent_level+1))" "Failed to upgrade $app_name: Not signed in to Mac App Store"
            indented_info "$((indent_level+2))" "Please sign in through the App Store app and try again"
          else
            indented_error_msg "$((indent_level+1))" "Failed to upgrade $app_name."
            if [[ -n "$upgrade_output" ]]; then
              indented_info "$((indent_level+2))" "Error: $upgrade_output"
            fi
          fi
          ((failed_count++))
        fi
      else
        success_tick_msg "$((indent_level+1))" "$app_name is already up to date."
        ((up_to_date_count++))
      fi
    fi
  done < "$masfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $updated_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "Mac App Store applications for '$category' updated successfully ($updated_count upgraded, $up_to_date_count up-to-date) (${duration}s)"
    return 0
  elif [[ $updated_count -eq 0 && $up_to_date_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "All Mac App Store applications for '$category' are up-to-date ($up_to_date_count packages) (${duration}s)"
    return 100
  elif [[ $failed_count -gt 0 ]]; then
    indented_error_msg "$indent_level" "Mac App Store update for '$category' completed with errors ($updated_count updated, $failed_count failed) (${duration}s)"
    return 1
  else
    success_tick_msg "$indent_level" "No Mac App Store applications to update for '$category' (${duration}s)"
    return 100
  fi
}
