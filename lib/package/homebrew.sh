#!/usr/bin/env bash

# lib/package/homebrew.sh - Homebrew package management

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_HOMEBREW_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_HOMEBREW_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/common.sh"

BREW_PACKAGES_DIR="${MEOW}/packages/homebrew"

# Check if brew package is installed
is_package_installed() {
  local package_name="$1"
  package_name=$(echo "$package_name" | xargs)

  if brew list --formula 2>/dev/null | grep -q "^${package_name}$"; then
    return 0
  fi

  if brew list --cask 2>/dev/null | grep -q "^${package_name}$"; then
    return 0
  fi

  if brew list "$package_name" &>/dev/null; then
    return 0
  fi

  return 1
}

# Set up Homebrew
setup_homebrew() {
  local indent="${1:-0}"
  step_header "$indent" "Setting up Homebrew"

  if ! command -v brew &>/dev/null; then
    indented_warning "$indent" "Homebrew not found. Installing..."

    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      success_tick_msg "$indent" "Homebrew installed successfully."

      # Try to load brew into PATH
      if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi

      if command -v brew &>/dev/null; then
        success_tick_msg "$indent" "Homebrew environment loaded successfully."
      else
        indented_warning "$indent" "Please restart your shell to use Homebrew."
      fi
    else
      indented_warning "$indent" "Homebrew installation failed, skipping Homebrew package updates."
      return 1
    fi
  else
    success_tick_msg "$indent" "Homebrew is already installed."
  fi

  if command -v brew &>/dev/null; then
    action_msg "$indent" "Updating Homebrew package index..."
    if brew update >/dev/null 2>&1; then
      success_tick_msg "$indent" "Homebrew package index updated successfully."
    else
      indented_warning "$indent" "Failed to update Homebrew package index."
    fi
  fi

  return 0
}

# Install brew packages with special Brewfile handling
install_brew_packages() {
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
  step_header "$indent_level" "Homebrew Packages ($category)"

  if [[ "$category" == "all" ]]; then
    indented_info "$((indent_level+1))" "Processing all Brewfile categories..."
    local overall_success=true
    for brewfile_path in "$BREW_PACKAGES_DIR"/*.Brewfile; do
      if [[ -f "$brewfile_path" ]]; then
        local current_category
        current_category=$(basename "$brewfile_path" .Brewfile)
        if ! install_brew_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done
    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All Homebrew package categories processed successfully."
      return 0
    else
      indented_warning "$indent_level" "Some Homebrew package categories encountered issues."
      return 1
    fi
  fi

  local brewfile="${BREW_PACKAGES_DIR}/${category}.Brewfile"
  if [[ ! -f "$brewfile" ]]; then
    indented_error_msg "$indent_level" "Brewfile not found: $brewfile"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi
    # Extract package name from Brewfile format (brew "package" or cask "package")
    package_name=$(echo "$line" | awk '{print $2}' | tr -d "'\"")

    if is_package_installed "$package_name"; then
      already_installed_packages+=("$package_name")
      already_installed_count=$((already_installed_count + 1))
    else
      local install_status
      run_package_operation "$((indent_level+1))" "$package_name" "install" \
        "Installing $package_name" \
        "Successfully installed $package_name." \
        "Failed to install $package_name." \
        "$package_name is already installed." \
        brew install "$package_name"
      install_status=$?

      if [ $install_status -eq 0 ]; then
        installed_packages+=("$package_name")
        installed_count=$((installed_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    fi
  done < "$brewfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "Homebrew packages processed successfully in ${duration}s."
    return 0
  else
    indented_warning "$indent_level" "Homebrew packages processed with $failed_count error(s) in ${duration}s."
    return 1
  fi
}

# Update brew packages with special Brewfile handling
update_brew_packages() {
  local category="${1:-all}"
  local indent_level="${2:-0}"
  local packages_upgraded_count=0
  local packages_verified_count=0
  local packages_failed_count=0
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Updating Homebrew Packages ($category)"

  if ! command -v brew &>/dev/null; then
    info_italic_msg "$indent_level" "Homebrew not available, skipping Homebrew package updates"
    return 100
  fi

  if [[ "$category" == "all" ]]; then
    action_msg "$((indent_level+1))" "Processing all Brewfile categories..."
    local overall_success=true
    for brewfile_path in "$BREW_PACKAGES_DIR"/*.Brewfile; do
      if [[ -f "$brewfile_path" ]]; then
        local current_category
        current_category=$(basename "$brewfile_path" .Brewfile)
        if ! update_brew_packages "$current_category" "$((indent_level+1))"; then
            overall_success=false
        fi
      fi
    done

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    if [[ "$overall_success" == true ]]; then
      success_tick_msg "$indent_level" "All Homebrew package categories updated successfully (${duration}s)"
      return 0
    else
      indented_warning "$indent_level" "Some Homebrew package categories encountered issues (${duration}s)"
      return 1
    fi
  fi

  local brewfile="${BREW_PACKAGES_DIR}/${category}.Brewfile"
  
  if [[ ! -f "$brewfile" ]]; then
    indented_error_msg "$indent_level" "Brewfile not found: $brewfile"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
      continue
    fi

    local package_name
    package_name=$(echo "$line" | awk '{print $2}' | tr -d "'\"")

    if is_package_installed "$package_name"; then
      local upgrade_status
      run_package_operation "$((indent_level+1))" "$package_name" "upgrade" \
        "Checking for updates to $package_name" \
        "Successfully upgraded $package_name." \
        "Failed to upgrade $package_name." \
        "$package_name is already up to date." \
        --pattern "(already installed|latest version is already installed)" \
        brew upgrade "$package_name"
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
  done < "$brewfile"

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $packages_failed_count -eq 0 ]]; then
    if [[ $packages_upgraded_count -gt 0 ]]; then
      success_tick_msg "$indent_level" "Homebrew packages for '$category' updated successfully ($packages_upgraded_count upgraded, $packages_verified_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All Homebrew packages for '$category' are up-to-date ($packages_verified_count packages) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Some Homebrew packages for '$category' failed ($packages_failed_count failures) (${duration}s)"
    return 1
  fi
}

# Update Homebrew index
update_homebrew_index() {
  local indent_level="${1:-0}"

  if ! command -v brew &>/dev/null; then
    indented_warning "$indent_level" "Homebrew not installed. Skipping Homebrew index update."
    return 1
  fi

  step_header "$indent_level" "Updating Homebrew Index"

  ui_spinner "$((indent_level+1))" "Updating Homebrew definitions (brew update)" --success "Homebrew definitions updated successfully." --fail "Failed to update Homebrew definitions." brew update --verbose

  success_tick_msg "$indent_level" "Homebrew index update completed"
  return 0
}

# Clean up Homebrew cache
cleanup_homebrew() {
  local indent_level=0
  local start_time end_time duration
  start_time=$(date +%s)

  if ! command -v brew &>/dev/null; then
    info_italic_msg "$indent_level" "Homebrew not available, skipping cleanup"
    return 0
  fi

  step_header "$indent_level" "Cleaning up Homebrew"

  local before_size after_size
  before_size=$(du -sh "$(brew --cache)" 2>/dev/null | awk '{print $1}')
  action_msg "$((indent_level+1))" "Current Homebrew cache size: $before_size"

  if ui_spinner "$((indent_level+1))" "Running Homebrew cleanup (prune all)" --success "Homebrew cache pruned successfully." --fail "Failed to prune Homebrew cache." brew cleanup --prune=all; then
    after_size=$(du -sh "$(brew --cache)" 2>/dev/null | awk '{print $1}')
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    success_tick_msg "$indent_level" "Cache size reduced to $after_size (was $before_size) (${duration}s)"
    return 0
  else
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    indented_error_msg "$indent_level" "Homebrew cleanup encountered issues (${duration}s)"
    return 1
  fi
}


