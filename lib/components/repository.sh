#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_REPOSITORY_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_REPOSITORY_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"

# Helper function to read YAML values
read_yaml_value() {
  local file="$1"
  local path="$2"
  yaml_read "$file" "$path" 2>/dev/null | tr -d '"'
}

# Check if component has repository configuration
# Args: $1 - component name
# Returns: 0 if component has repository config, 1 otherwise
has_component_repository_config() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1
  yaml_path_exists "$component_file" ".repository.url"
}

# Get repository URL from component configuration
# Args: $1 - component name
# Returns: Repository URL or empty if not configured
get_component_repository_url() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  read_yaml_value "$component_file" ".repository.url"
}

# Get repository branch or tag from component configuration
# Args: $1 - component name
# Returns: Branch/tag name, defaults to "main" if not specified
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
# Args:
#   $1 - component name
clone_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Remove existing repository if present
  if [[ -d "$installed_dir" ]]; then
    step_header "Removing existing repository for component: $component"
    rm -rf "$installed_dir"
  fi

  # Get repository configuration
  local repo_url branch_or_tag
  repo_url=$(get_component_repository_url "$component")
  branch_or_tag=$(get_component_repository_branch "$component")

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cloning repository to .downloads/$component"
  fi

  # Clone repository with spinner
  mkdir -p "$(dirname "$installed_dir")"

  ui_spinner "Cloning $component repository" \
    --success "Repository cloned successfully" \
    --fail "Failed to clone repository" \
    git clone --depth 1 -b "$branch_or_tag" "$repo_url" "$installed_dir"

  return $?
}

# Update existing component repository
# Args:
#   $1 - component name
update_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Clone if repository doesn't exist
  if [[ ! -d "$installed_dir" ]]; then
    warning "Repository not found, cloning to .downloads/$component instead"
    clone_component_repository "$component"
    return $?
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Updating repository for component: $component"
  fi

  # Update repository using git with spinner
  ui_spinner "Updating $component repository" \
    --success "Repository updated successfully" \
    --fail "Failed to update repository" \
    sh -c "cd '$installed_dir' && git fetch && git reset --hard \"origin/\$(git rev-parse --abbrev-ref HEAD)\""

  if [[ $? -ne 0 ]]; then
    warning "Failed to update repository, trying to re-clone"
    clone_component_repository "$component"
    return $?
  fi

  return 0
}

# Clean up component repository
# Args:
#   $1 - component name
cleanup_component_repository() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 0

  # Skip if component doesn't have repository config
  if ! yaml_path_exists "$component_file" ".repository"; then
    return 0
  fi

  local repo_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Remove repository directory if it exists
  if [[ -d "${repo_dir}/.git" ]]; then
    step_header "Cleaning up repository for $component"

    rm -rf "$repo_dir" || {
      error "Failed to remove repository directory: $repo_dir"
      return 1
    }

    success_tick_msg "Repository cleaned up for $component"
  fi
}
