#!/usr/bin/env bash

# lib/strings/strings.sh - Unified strings file with modular structure

if [[ -n "${_LIB_STRINGS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_SOURCED=1

# ============================================================================
# CORE STATIC MESSAGES
# ============================================================================

declare -A UI_STATIC_MESSAGES=(
  # General operations
  ["session_init_failed"]="Session initialization failed"
  ["installation_order"]="Installation order:"
  ["update_order"]="Update order:"
  ["uninstall_order"]="Uninstall order:"
  ["no_components_to_install"]="No components to install"
  ["no_components_to_update"]="No components to update"
  ["all_components_installed"]="All components already installed"

  # System setup
  ["available_presets"]="Available Presets"
  ["updating_all_components"]="Updating all installed components"
  ["no_components_installed"]="No components are currently installed"
  ["zsh_setup_issues"]="Zsh environment setup encountered issues"
  ["tmux_setup_issues"]="tmux environment setup encountered issues"

  # Status messages
  ["already_installed"]="already installed"
  ["up_to_date"]="up-to-date"
  ["already_correct"]="already correct"
  ["not_installed"]="not installed"
  ["incompatible"]="incompatible"
  ["available"]="available"
  ["installed"]="installed"
  ["installed_manual"]="installed (manual)"

  # Confirmation
  ["confirm_default"]="Confirm"

  # Commands and errors
  ["command_output"]="Command output:"
  ["command_failed_first_lines"]="Command failed. First few lines of output:"

  # Component operations
  ["component_setup_completed"]="Component setup completed successfully"
  ["component_setup_failed"]="Component setup failed"
  ["component_cleanup_completed"]="Component cleanup completed successfully"
  ["component_cleanup_failed"]="Component cleanup failed"
  ["component_tracking_removed"]="Component tracking removed"

  # Repository operations
  ["repo_updated"]="Repository updated successfully"
  ["repo_cleaned"]="Repository cleaned up"

  # Package operations
  ["packages_updated"]="Packages updated successfully"
  ["packages_uninstalled"]="Packages uninstalled successfully"
  ["package_updates_failed"]="Some package updates may have failed"
  ["package_uninstall_failed"]="Some package uninstallation may have failed"

  # Symlinks operations
  ["symlinks_restored"]="Symlinks removed and backups restored successfully"

  # Package managers
  ["npm_not_found"]="npm not found"
  ["go_not_found"]="Go not found"
  ["mas_not_found"]="mas CLI not found"
  ["homebrew_not_found"]="Homebrew not found. Installing..."

  # macOS specific
  ["macos_config_only"]="macOS keyboard layout configuration only works on macOS"
  ["not_running_macos"]="Not running on macOS. Skipping macOS configuration."
  ["not_running_macos_finder"]="Not running on macOS. Skipping Finder configuration."
  ["computer_name_prompt"]="Do you want to set a new computer name?"
  ["enter_computer_name"]="Enter your desired computer name: "

  # MOTD fallbacks
  ["motd_fallback"]="A fancy digital cat comment should be here"
  ["motd_greeting_default"]="Meowvelous day"
  ["motd_time_fallback"]="Hope you have a purr-ductive time!"
  ["motd_uptime_fallback"]="Your system is up and running!"
  ["motd_disk_fallback"]="May your storage be plentiful!"
  ["motd_ram_fallback"]="May your memory serve you well, comrade!"
  ["motd_update_comment"]="Time for some updates!"
)

# ============================================================================
# TEMPLATE MESSAGES - Strings with parameters using printf format
# ============================================================================

declare -A UI_TEMPLATE_MESSAGES=(
  # General operations with counts
  ["components_install_count"]="Will install %d component%s with dependencies"
  ["components_update_count"]="Will update %d component%s with dependencies"
  ["total_components_install"]="Total components to install: %d"
  ["total_components_update"]="Total components to update: %d"
  ["found_components"]="Found %d installed components: %s"
  ["command_more_lines_hidden"]="... and %d more lines. Use MEOW_VERBOSE=true for full output"

  # Component operations
  ["setting_up_component"]="Setting up component: %s"
  ["cleaning_component"]="Cleaning up component: %s"
  ["installing_component"]="Installing component: %s"
  ["updating_component"]="Updating component: %s"
  ["uninstalling_component"]="Uninstalling component: %s"
  ["component_installed"]="Component installed successfully: %s"
  ["component_updated"]="Component updated successfully: %s"
  ["component_uninstalled"]="Component uninstalled successfully: %s"
  ["component_not_found"]="Component '%s' not found"
  ["component_not_available"]="Component '%s' is not available on this platform or dependencies are missing"
  ["component_already_installed"]="Component '%s' is already installed"
  ["component_marked_manual"]="Component '%s' marked as manually installed"
  ["component_install_failed"]="Failed to install component: %s"
  ["component_packages_failed"]="Failed to install packages for component '%s'"
  ["component_repo_failed"]="Failed to clone repository for component '%s'"

  # Repository operations
  ["removing_repo"]="Removing existing repository for component: %s"
  ["cloning_repo"]="Cloning repository to .downloads/%s"
  ["updating_repo"]="Updating repository for component: %s"
  ["cleaning_repo"]="Cleaning up repository for %s"
  ["cloning_component_repo"]="Cloning %s repository"
  ["updating_component_repo"]="Updating %s repository"
  ["repo_component_install"]="Installing repository-based component: %s"
  ["repo_cleaned_for"]="Repository cleaned up for %s"
  ["repo_update_msg"]="Updating repository for component: %s"
  ["repo_cloned_success"]="Repository cloned successfully for %s"
  ["repo_clone_failed"]="Failed to clone repository for %s"
  ["repo_updated_success"]="Repository updated successfully for %s"
  ["repo_update_failed"]="Failed to update repository for %s"

  # Package operations
  ["installing_packages"]="Installing packages for %s"
  ["updating_packages"]="Updating packages for %s"
  ["removing_packages"]="Uninstalling packages"
  ["packages_manager_display"]="(%s) %s"
  ["package_manager_removal"]="%s Package Removal (%s)"

  # Symlinks operations
  ["setting_up_symlinks"]="Setting up symlinks for component: %s"
  ["removing_symlinks"]="Removing symlinks for component: %s"
  ["symlinks_configured"]="Symlinks for '%s' configured successfully"
  ["symlinks_removed"]="Symlinks for '%s' removed successfully"
  ["symlinks_completed"]="Symlinks for '%s' completed (%ss)"

  # Package managers
  ["setting_up_manager"]="Setting up %s"
  ["manager_ready"]="%s ready"
  ["cleaning_manager"]="Cleaning %s"
  ["manager_cleanup_completed"]="%s cleanup completed"
  ["setting_up_package_manager"]="Setting up %s..."
  ["cleaning_package_manager"]="Cleaning %s..."

  # Lists and items
  ["requested_components"]="Requested components: %s"
  ["new_dependencies"]="New dependencies: %s"
  ["preset_components"]="Preset components: %s"
  ["dependencies_list"]="Dependencies: %s"

  # Presets
  ["installing_preset"]="==> Installing Preset: %s"
  ["preset_not_found"]="Preset '%s' not found"
  ["preset_not_available"]="Preset '%s' is not available on this platform"
  ["preset_already_installed"]="Preset '%s' is already installed"
  ["preset_not_installed"]="Preset '%s' is not installed"
  ["preset_updated"]="Preset '%s' updated successfully"
  ["preset_failed_components"]="Failed to install required components"
  ["preset_no_components"]="No components to install for this preset"
  ["preset_components_count"]="Will install %d preset components with dependencies"
  ["preset_components_update_msg"]="Updating preset components"

  # Errors
  ["no_components_specified_install"]="No components specified for installation"
  ["no_components_specified_update"]="No components specified for update"
  ["no_components_specified_uninstall"]="No components specified for uninstall"

  # MOTD templates
  ["motd_greeting"]="%s, сomrade %s!"
  ["motd_calendar"]="Calendar shows %s."
  ["motd_clock"]="Clock purrs at %s."
  ["motd_system_territory"]="Let me tell you about your digital territory, comrade:"
  ["motd_system_info"]="System:     %s"
  ["motd_shell_info"]="Shell:      %s"
  ["motd_uptime_info"]="Uptime:     %s"
  ["motd_disk_info"]="Disk:       %s"
  ["motd_ram_info"]="RAM:        %s"
  ["motd_updates_info"]="Updates:    %s packages need updating"
  ["motd_computer_name_set"]="Computer name set to %s"

  # macOS configuration
  ["macos_setting_computer_name"]="Computer name set to %s"
  ["macos_system_defaults"]="System Defaults"
  ["macos_finder_config"]="Finder Configuration"
  ["macos_dock_config"]="Dock Configuration"
  ["macos_app_config"]="App Configuration"
  ["macos_configuration"]="macOS Configuration"

  # Package manager summaries
  ["package_summary_installed"]="%s: ✓ %d installed, %d already present"
  ["package_summary_present"]="%s: ✓ %d/%d already present"
  ["package_summary_failed"]="%s: ✗ %d failed, %d installed, %d already present"
  ["package_summary_updated"]="%s: ✓ %d updated, %d up-to-date"
  ["package_summary_update_failed"]="%s: ✗ %d failed, %d updated, %d up-to-date"
  ["package_summary_uninstalled"]="%s: ✓ %d uninstalled, %d not installed"
  ["package_summary_uninstall_failed"]="%s: ✗ %d failed, %d uninstalled, %d not installed"
)

# ============================================================================
# SPINNER MESSAGES - Progress|Success|Fail triplets for ui_spinner
# ============================================================================

declare -A UI_SPINNER_MESSAGES=(
  # Package managers
  ["homebrew_install"]="Installing Homebrew|Homebrew installed successfully|Homebrew installation failed"
  ["homebrew_cleanup"]="Cleaning Homebrew|Homebrew cleanup completed|Homebrew cleanup failed"
  ["homebrew_prune"]="Pruning cache and unused packages|Homebrew cleanup completed|Homebrew cleanup failed"

  ["npm_cache_clean"]="Cleaning npm cache|npm cache cleaned|npm cache cleanup failed"
  ["npm_clean"]="Cleaning npm|npm cache cleaned|npm cleanup failed"

  ["apt_update"]="Updating APT index|APT index updated|Failed to update APT index"
  ["apt_cleanup"]="Cleaning APT|APT cleanup completed|APT cleanup failed"
  ["apt_remove_unused"]="Removing unused packages|Unused packages removed|Failed to remove unused packages"
  ["apt_clean_cache"]="Cleaning cache|Cache cleaned|Failed to clean cache"

  ["apk_update"]="Updating apk index|apk index updated|Failed to update apk index"
  ["apk_cleanup"]="Cleaning apk|apk cleanup completed|apk cleanup failed"

  ["pacman_sync"]="Syncing package database|Package database synced|Failed to sync package database"
  ["pacman_cleanup"]="Cleaning pacman|pacman cleanup completed|pacman cleanup failed"
  ["pacman_prune"]="Pruning cache|Cache pruned|Failed to prune cache"

  # System setup
  ["oh_my_zsh_install"]="Installing Oh My Zsh|Oh My Zsh installation completed|Failed to install Oh My Zsh"
  ["oh_my_zsh_update"]="Updating Oh My Zsh|Oh My Zsh update completed|Failed to update Oh My Zsh"

  ["tmux_tpm_install"]="Installing tmux Plugin Manager|tmux Plugin Manager installation completed|Failed to install tmux Plugin Manager"
  ["tmux_tpm_update"]="Updating tmux Plugin Manager|tmux Plugin Manager update completed|Failed to update tmux Plugin Manager"

  ["rust_install"]="Installing Rust toolchain with rustup|Rust toolchain installed successfully|Failed to install Rust toolchain"
  ["rust_clippy"]="Installing clippy component|clippy installed|Failed to install clippy component"
  ["rust_analyzer"]="Installing rust-analyzer component|rust-analyzer installed|Failed to install rust-analyzer component"

  # Package manager initialization
  ["init_apk"]="Initializing apk package manager|apk package manager ready|apk initialization failed"
  ["init_apt"]="Initializing APT package manager|APT package manager ready|APT initialization failed"
  ["init_pacman"]="Initializing pacman package manager|pacman package manager ready|pacman initialization failed"
  ["init_homebrew"]="Initializing Homebrew package manager|Homebrew package manager ready|Homebrew initialization failed"

  # Tools installation
  ["install_yq"]="Installing yq v%s|yq v%s installed to /usr/local/bin/yq|Failed to download yq from %s"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a static message by key
get_static_message() {
  local key="$1"
  echo "${UI_STATIC_MESSAGES[$key]:-$key}"
}

# Format a template message with parameters
format_template_message() {
  local template_key="$1"
  shift
  local template="${UI_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}

# Get spinner message parts (returns: progress|success|fail)
get_spinner_messages() {
  local key="$1"
  echo "${UI_SPINNER_MESSAGES[$key]:-$key||}"
}

# Parse spinner messages into individual parts
parse_spinner_messages() {
  local key="$1"
  local messages
  messages=$(get_spinner_messages "$key")
  IFS='|' read -r progress_msg success_msg fail_msg <<<"$messages"

  # Export for caller to use
  export SPINNER_PROGRESS="$progress_msg"
  export SPINNER_SUCCESS="$success_msg"
  export SPINNER_FAIL="$fail_msg"
}
