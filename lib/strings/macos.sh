#!/usr/bin/env bash

# lib/strings/macos.sh - macOS-specific UI strings

if [[ -n "${_LIB_STRINGS_MACOS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_MACOS_SOURCED=1

# ============================================================================
# STATIC MESSAGES - macOS specific
# ============================================================================

declare -A UI_MACOS_STATIC_MESSAGES=(
  # macOS specific
  ["macos_config_only"]="macOS keyboard layout configuration only works on macOS"
  ["not_running_macos"]="Not running on macOS. Skipping macOS configuration."
  ["not_running_macos_finder"]="Not running on macOS. Skipping Finder configuration."
  ["computer_name_prompt"]="Do you want to set a new computer name?"
  ["enter_computer_name"]="Enter your desired computer name: "
)

# ============================================================================
# TEMPLATE MESSAGES - macOS configuration with parameters
# ============================================================================

declare -A UI_MACOS_TEMPLATE_MESSAGES=(
  # macOS configuration
  ["macos_setting_computer_name"]="Computer name set to %s"
  ["macos_system_defaults"]="System Defaults"
  ["macos_finder_config"]="Finder Configuration"
  ["macos_dock_config"]="Dock Configuration"
  ["macos_app_config"]="App Configuration"
  ["macos_configuration"]="macOS Configuration"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a macOS static message by key
get_macos_static_message() {
  local key="$1"
  echo "${UI_MACOS_STATIC_MESSAGES[$key]:-$key}"
}

# Format a macOS template message with parameters
format_macos_template_message() {
  local template_key="$1"
  shift
  local template="${UI_MACOS_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}
