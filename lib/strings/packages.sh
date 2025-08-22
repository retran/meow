#!/usr/bin/env bash

# lib/strings/packages.sh - Package manager and package operation UI strings

if [[ -n "${_LIB_STRINGS_PACKAGES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_PACKAGES_SOURCED=1

# ============================================================================
# STATIC MESSAGES - Package operations
# ============================================================================

declare -A UI_PACKAGE_STATIC_MESSAGES=(
  # Package operations
  ["packages_updated"]="Packages updated successfully"
  ["packages_uninstalled"]="Packages uninstalled successfully"
  ["package_updates_failed"]="Some package updates may have failed"
  ["package_uninstall_failed"]="Some package uninstallation may have failed"

  # Package managers
  ["npm_not_found"]="npm not found"
  ["go_not_found"]="Go not found"
  ["mas_not_found"]="mas CLI not found"
  ["homebrew_not_found"]="Homebrew not found. Installing..."
)

# ============================================================================
# TEMPLATE MESSAGES - Package operations with parameters
# ============================================================================

declare -A UI_PACKAGE_TEMPLATE_MESSAGES=(
  # Package operations
  ["installing_packages"]="Installing packages for %s"
  ["updating_packages"]="Updating packages for %s"
  ["removing_packages"]="Uninstalling packages"
  ["packages_manager_display"]="(%s) %s"
  ["package_manager_removal"]="%s Package Removal (%s)"

  # Package managers
  ["setting_up_manager"]="Setting up %s"
  ["manager_ready"]="%s ready"
  ["cleaning_manager"]="Cleaning %s"
  ["manager_cleanup_completed"]="%s cleanup completed"
  ["setting_up_package_manager"]="Setting up %s..."
  ["cleaning_package_manager"]="Cleaning %s..."

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
# SPINNER MESSAGES - Package manager operations
# ============================================================================

declare -A UI_PACKAGE_SPINNER_MESSAGES=(
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

  # Package manager initialization
  ["init_apk"]="Initializing apk package manager|apk package manager ready|apk initialization failed"
  ["init_apt"]="Initializing APT package manager|APT package manager ready|APT initialization failed"
  ["init_pacman"]="Initializing pacman package manager|pacman package manager ready|pacman initialization failed"
  ["init_homebrew"]="Initializing Homebrew package manager|Homebrew package manager ready|Homebrew initialization failed"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a package static message by key
get_package_static_message() {
  local key="$1"
  echo "${UI_PACKAGE_STATIC_MESSAGES[$key]:-$key}"
}

# Format a package template message with parameters
format_package_template_message() {
  local template_key="$1"
  shift
  local template="${UI_PACKAGE_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}

# Get package spinner message parts
get_package_spinner_messages() {
  local key="$1"
  echo "${UI_PACKAGE_SPINNER_MESSAGES[$key]:-$key||}"
}

# Parse package spinner messages into individual parts
parse_package_spinner_messages() {
  local key="$1"
  local messages
  messages=$(get_package_spinner_messages "$key")
  IFS='|' read -r progress_msg success_msg fail_msg <<<"$messages"

  # Export for caller to use
  export SPINNER_PROGRESS="$progress_msg"
  export SPINNER_SUCCESS="$success_msg"
  export SPINNER_FAIL="$fail_msg"
}
