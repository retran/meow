#!/usr/bin/env bash

# lib/strings/components.sh - Component operation UI strings

if [[ -n "${_LIB_STRINGS_COMPONENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_COMPONENTS_SOURCED=1

# ============================================================================
# STATIC MESSAGES - Component operations
# ============================================================================

declare -A UI_COMPONENT_STATIC_MESSAGES=(
  # Component operations
  ["component_setup_completed"]="Component setup completed successfully"
  ["component_setup_failed"]="Component setup failed"
  ["component_cleanup_completed"]="Component cleanup completed successfully"
  ["component_cleanup_failed"]="Component cleanup failed"
  ["component_tracking_removed"]="Component tracking removed"

  # Symlinks operations
  ["symlinks_restored"]="Symlinks removed and backups restored successfully"
)

# ============================================================================
# TEMPLATE MESSAGES - Component operations with parameters
# ============================================================================

declare -A UI_COMPONENT_TEMPLATE_MESSAGES=(
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

  # Symlinks operations
  ["setting_up_symlinks"]="Setting up symlinks for component: %s"
  ["removing_symlinks"]="Removing symlinks for component: %s"
  ["symlinks_configured"]="Symlinks for '%s' configured successfully"
  ["symlinks_removed"]="Symlinks for '%s' removed successfully"
  ["symlinks_completed"]="Symlinks for '%s' completed (%ss)"

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
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a component static message by key
get_component_static_message() {
  local key="$1"
  echo "${UI_COMPONENT_STATIC_MESSAGES[$key]:-$key}"
}

# Format a component template message with parameters
format_component_template_message() {
  local template_key="$1"
  shift
  local template="${UI_COMPONENT_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}
