#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_REPOSITORY_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_REPOSITORY_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/core/dry_run.sh"

has_component_repository_config() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1
  yaml_path_exists "$component_file" ".repository.url"
}

get_component_repository_url() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  read_yaml_value "$component_file" ".repository.url"
}

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

clone_component_repository() {
  set -eu
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  local repo_url branch_or_tag
  repo_url=$(get_component_repository_url "$component")
  branch_or_tag=$(get_component_repository_branch "$component")

  if dry_run_git_operation "clone" "$installed_dir" "$(_f "%s (branch: %s)" "$repo_url" "$branch_or_tag")"; then
    return 0
  fi

  if [[ -d "$installed_dir" ]]; then
    ui_step_header "$(_f "Removing existing repository for component: %s" "$component")"
    rm -rf "$installed_dir" || {
      ui_error "$(_f "Failed to remove existing repository directory: %s" "$installed_dir")"
      return 1
    }
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Cloning repository to .downloads/%s" "$component")"
  fi

  mkdir -p "$(dirname "$installed_dir")" || {
    ui_error "$(_f "Failed to create parent directory for %s" "$installed_dir")"
    return 1
  }

  local clone_message="$(_f "Cloning repository for '%s'..." "$component")"
  ui_spinner "$clone_message" \
    git clone --depth 1 -b "$branch_or_tag" "$repo_url" "$installed_dir"

  return $?
}

update_component_repository() {
  set -eu
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  if dry_run_git_operation "pull" "$installed_dir"; then
    return 0
  fi

  if [[ ! -d "$installed_dir" ]]; then
    ui_warning "$(_f "Repository for '%s' not found. Cloning to .downloads/%s instead." "$component" "$component")"
    clone_component_repository "$component"
    return $?
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Updating repository for component: %s" "$component")"
  fi

  local update_message="$(_f "Updating repository for '%s'..." "$component")"

  ui_spinner "$update_message" \
    sh -c "
      set -eu
      cd '$installed_dir' || exit 1
      git fetch || exit 1
      GIT_BRANCH_NAME=\$(git rev-parse --abbrev-ref HEAD || exit 1)
      git reset --hard \"origin/\$GIT_BRANCH_NAME\" || exit 1
    "

  local update_status=$?

  if [ "$update_status" -ne 0 ]; then
    ui_warning "$(_f "Failed to update repository for '%s', trying to re-clone..." "$component")"
    clone_component_repository "$component"
    return $?
  fi

  return 0
}

cleanup_component_repository() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 0

  if ! yaml_path_exists "$component_file" ".repository"; then
    return 0
  fi

  local repo_dir="${MEOW_DOWNLOADS_DIR}/${component}"
  local cleanup_successful_status=0

  if [[ -d "${repo_dir}/.git" ]]; then
    ui_step_header "$(_f "Cleaning up repository for '%s'" "$component")"

    if is_dry_run; then
      dry_run_file_operation "remove_directory" "$repo_dir"
      cleanup_successful_status=$?
    else
      rm -rf "$repo_dir"
      cleanup_successful_status=$?
      if [ "$cleanup_successful_status" -ne 0 ]; then
        ui_error "$(_f "Failed to remove repository directory: %s" "$repo_dir")"
        return 1
      fi
    fi

    if [ "$cleanup_successful_status" -eq 0 ]; then
      ui_action_success "$(_f "Repository cleaned up for '%s'" "$component")"
    fi
  fi
  return 0
}
