#!/usr/bin/env bash

# lib/package/vscode.sh - Functions for managing VS Code extensions in the dotfiles package

# Guard against multiple sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_VSCODE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_VSCODE_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

VSCODE_PACKAGES_DIR="${DOTFILES_DIR}/packages/vscode"

# Helper function to check if a VS Code extension is installed
is_vscode_extension_installed() {
  local extension_id="$1"
  # Redirect stderr to suppress SIGPIPE errors and use a more robust check
  local extensions
  extensions=$(code --list-extensions 2>/dev/null) || return 1
  echo "$extensions" | grep -qi "^${extension_id}$"
}

# Helper function to check if VS Code is available
check_vscode_available() {
  local indent_level="$1"

  if ! command -v code &>/dev/null; then
    indented_error_msg "$indent_level" "VS Code CLI (code) is required but not available."
    indented_info "$((indent_level+1))" "Please ensure VS Code is installed and the 'code' command is in your PATH."
    indented_info "$((indent_level+1))" "You can install the CLI from VS Code: View > Command Palette > 'Shell Command: Install code command in PATH'"
    return 1
  fi
  return 0
}

install_vscode_extensions() {
  local category="$1"
  local indent_level="${2:-1}"
  local extension_id
  local installed_count=0
  local already_installed_count=0
  local failed_count=0
  local start_time end_time duration
  local installed_extensions=()
  local already_installed_extensions=()

  start_time=$(date +%s)

  step_header "$indent_level" "VS Code Extensions ($category)"

  # Check if VS Code is available
  if ! check_vscode_available "$indent_level"; then
    return 1
  fi

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all VS Code extension categories..."
    local overall_success=true
    for vscode_file_path in "$VSCODE_PACKAGES_DIR"/*.Vscodefile; do
      if [[ -f "$vscode_file_path" ]]; then
        local current_category
        current_category=$(basename "$vscode_file_path" .Vscodefile)
        if ! install_vscode_extensions "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All VS Code extension categories processed successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some VS Code extension categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local vscodefile="${VSCODE_PACKAGES_DIR}/${category}.Vscodefile"

  if [[ ! -f "$vscodefile" ]]; then
    info_italic_msg "$indent_level" "No VS Code extensions defined for category: $category"
    return 0
  fi

  # Process each line in the Vscodefile
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract extension ID (remove "extension" prefix and quotes)
    extension_id=$(echo "$line" | sed 's/^[[:space:]]*extension[[:space:]]*["'"'"']*\([^"'"'"']*\)["'"'"']*.*/\1/' | xargs)

    if is_vscode_extension_installed "$extension_id"; then
      info_italic_msg "$((indent_level+1))" "$extension_id already installed, skipping"
      already_installed_extensions+=("$extension_id")
      ((already_installed_count++))
    else
      if ui_spinner "$((indent_level+1))" "Installing VS Code extension $extension_id" \
        --success "$extension_id installed successfully" \
        --fail "Failed to install $extension_id" \
        code --install-extension "$extension_id" --force; then
        installed_extensions+=("$extension_id")
        ((installed_count++))
      else
        ((failed_count++))
      fi
    fi
  done < "$vscodefile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Summary message
  if [[ $installed_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "VS Code extensions for '$category' installed successfully ($installed_count installed, $already_installed_count already installed) (${duration}s)"
  elif [[ $installed_count -eq 0 && $already_installed_count -gt 0 && $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "All VS Code extensions for '$category' are already installed ($already_installed_count extensions) (${duration}s)"
  elif [[ $failed_count -gt 0 ]]; then
    indented_error_msg "$indent_level" "VS Code extension installation for '$category' completed with errors ($installed_count installed, $failed_count failed) (${duration}s)"
    return 1
  else
    success_tick_msg "$indent_level" "No VS Code extensions to install for '$category' (${duration}s)"
  fi

  return 0
}

update_vscode_extensions() {
  local category="$1"
  local indent_level="${2:-1}"
  local extension_id
  local updated_count=0
  local up_to_date_count=0
  local failed_count=0
  local start_time end_time duration

  start_time=$(date +%s)

  step_header "$indent_level" "Updating VS Code Extensions ($category)"

  if ! check_vscode_available "$indent_level"; then
    return 1
  fi

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all VS Code extension categories..."
    local overall_success=true
    for vscode_file_path in "$VSCODE_PACKAGES_DIR"/*.Vscodefile; do
      if [[ -f "$vscode_file_path" ]]; then
        local current_category
        current_category=$(basename "$vscode_file_path" .Vscodefile)
        if ! update_vscode_extensions "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All VS Code extension categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some VS Code extension categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local vscodefile="${VSCODE_PACKAGES_DIR}/${category}.Vscodefile"

  if [[ ! -f "$vscodefile" ]]; then
    info_italic_msg "$indent_level" "No VS Code extensions defined for category: $category"
    return 0
  fi

  action_msg "$((indent_level+1))" "Checking for outdated extensions in category: $category"

  if ! ui_spinner "$((indent_level+1))" "Updating all VS Code extensions" \
    --success "VS Code extensions updated successfully" \
    --fail "Failed to update VS Code extensions" \
    code --update-extensions; then
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    extension_id=$(echo "$line" | sed 's/^[[:space:]]*extension[[:space:]]*["'"'"']*\([^"'"'"']*\)["'"'"']*.*/\1/' | xargs)

    if ! is_vscode_extension_installed "$extension_id"; then
      info_italic_msg "$((indent_level+1))" "$extension_id not installed, skipping"
      continue
    fi

    success_tick_msg "$((indent_level+1))" "$extension_id is up to date"
    ((up_to_date_count++))
  done < "$vscodefile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  # Summary message
  if [[ $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "All VS Code extensions for '$category' are up-to-date ($up_to_date_count extensions) (${duration}s)"
  else
    indented_error_msg "$indent_level" "VS Code extension update for '$category' completed with errors ($failed_count failed) (${duration}s)"
    return 1
  fi

  return 0
}
