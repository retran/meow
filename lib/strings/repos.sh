#!/usr/bin/env bash

# lib/strings/repos.sh - Repository operation UI strings

if [[ -n "${_LIB_STRINGS_REPOS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_REPOS_SOURCED=1

# ============================================================================
# STATIC MESSAGES - Repository operations
# ============================================================================

declare -A UI_REPO_STATIC_MESSAGES=(
  # Repository operations
  ["repo_updated"]="Repository updated successfully"
  ["repo_cleaned"]="Repository cleaned up"
)

# ============================================================================
# TEMPLATE MESSAGES - Repository operations with parameters
# ============================================================================

declare -A UI_REPO_TEMPLATE_MESSAGES=(
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
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a repository static message by key
get_repo_static_message() {
  local key="$1"
  echo "${UI_REPO_STATIC_MESSAGES[$key]:-$key}"
}

# Format a repository template message with parameters
format_repo_template_message() {
  local template_key="$1"
  shift
  local template="${UI_REPO_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}
