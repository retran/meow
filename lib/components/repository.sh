#!/usr/bin/env bash

# Helper function for safe string formatting, injected by the inliner script.
source "${MEOW}/lib/core/ui.sh"

if [[ -n "${_LIB_COMPONENTS_REPOSITORY_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_REPOSITORY_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/core/dry_run.sh"

# Check if component has repository configuration
has_component_repository_config() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1
  yaml_path_exists "$component_file" ".repository.url"
}

# Get repository URL from component configuration
get_component_repository_url() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  read_yaml_value "$component_file" ".repository.url"
}

# Get repository branch or tag from component configuration
get_component_repository_branch() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  local branch tag
  branch=$(read_yaml_value "$component_file" ".repository.branch")
  tag=$(read_yaml_value "$component_file" ".repository.tag")

  if [[ -n "$tag" && "$tag" != "null" ]]; then
    echo "$tag"
  elif [[ -n "$branch" && "$branch" != "null" ]]; then
    echo "$branch"
  else
    echo "main"
  fi
}

# Clone component repository to installation directory
clone_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  local repo_url branch_or_tag
  repo_url=$(get_component_repository_url "$component")
  branch_or_tag=$(get_component_repository_branch "$component")

  if dry_run_git_operation "clone" "$installed_dir" "$repo_url (branch: $branch_or_tag)"; then
    return 0
  fi

  if [[ -d "$installed_dir" ]]; then
    ui_step_header "$(_f "Removing existing repository for component: %s" "$component")"
    rm -rf "$installed_dir"
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(_f "Cloning repository to .downloads/%s" "$component")"
  fi

  mkdir -p "$(dirname "$installed_dir")"

  ui_spinner "$(parse_spinner_messages "clone_repository" "$component")" \
    git clone --depth 1 -b "$branch_or_tag" "$repo_url" "$installed_dir"

  return $?
}

# Update existing component repository
update_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  if dry_run_git_operation "pull" "$installed_dir"; then
    return 0
  fi

  if [[ ! -d "$installed_dir" ]]; then
    ui_warning "$(_f "Repository not found, cloning to .downloads/%s instead" "$component")"
    clone_component_repository "$component"
    return $?
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(_f "Updating repository for component: %s" "$component")"
  fi

  ui_spinner "$(parse_spinner_messages "update_repository" "$component")" \
    sh -c "cd '$installed_dir' && git fetch && git reset --hard \"origin/\$(git rev-parse --abbrev-ref HEAD)\""

  if [[ $? -ne 0 ]]; then
    ui_warning "Failed to update repository, trying to re-clone"
    clone_component_repository "$component"
    return $?
  fi

  return 0
}

# Clean up component repository
cleanup_component_repository() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 0

  if ! yaml_path_exists "$component_file" ".repository"; then
    return 0
  fi

  local repo_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  if [[ -d "${repo_dir}/.git" ]]; then
    ui_step_header "$(_f "Cleaning up repository for %s" "$component")"

    if is_dry_run; then
      dry_run_file_operation "remove_directory" "$repo_dir"
    else
      rm -rf "$repo_dir" || {
        ui_error "$(_f "Failed to remove repository directory: %s" "$repo_dir")"
        return 1
      }
    fi

    ui_action_success "$(_f "Repository cleaned up for %s" "$component")"
  fi
}
