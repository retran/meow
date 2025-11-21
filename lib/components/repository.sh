#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/components/repository.sh
# @brief: Git repository cloning and management for component-specific configurations.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_COMPONENTS_REPOSITORY_SOURCED:-}" ]; then
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

  if [ ! -f "$component_file" ]; then
    return 1
  fi
  yaml_path_exists "$component_file" ".repository.url"
}

get_component_repository_url() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  read_yaml_value "$component_file" ".repository.url"
}

get_component_repository_branch() {
  get_component_repository_ref "$@"
}

get_component_repository_ref() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  local branch tag
  branch=$(read_yaml_value "$component_file" ".repository.branch")
  tag=$(read_yaml_value "$component_file" ".repository.tag")

  if [ -n "$tag" ] && [ "$tag" != "null" ]; then
    echo "$tag"
  elif [ -n "$branch" ] && [ "$branch" != "null" ]; then
    echo "$branch"
  else
    echo "main"
  fi
}

get_component_repository_mode() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  local tag
  tag=$(read_yaml_value "$component_file" ".repository.tag")

  if [ -n "$tag" ] && [ "$tag" != "null" ]; then
    echo "tag"
  else
    echo "branch"
  fi
}

clone_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  local repo_url checkout_ref
  repo_url=$(get_component_repository_url "$component")
  checkout_ref=$(get_component_repository_ref "$component")

  if dry_run_git_operation "clone" "$installed_dir" "$(_f "%s (ref: %s)" "$repo_url" "$checkout_ref")"; then
    return 0
  fi

  if [ -d "$installed_dir" ]; then
    ui_step_header "$(_f "Removing existing repository for component: %s" "$component")"
    rm -rf "$installed_dir" || {
      ui_error "$(_f "Failed to remove existing repository directory: %s" "$installed_dir")"
      return 1
    }
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Cloning repository to .downloads/%s" "$component")"
  fi

  mkdir -p "$(dirname "$installed_dir")" || {
    ui_error "$(_f "Failed to create parent directory for %s" "$installed_dir")"
    return 1
  }

  local clone_message="$(_f "Cloning repository for '%s'..." "$component")"
  ui_spinner "$clone_message" \
    git clone --depth 1 -b "$checkout_ref" "$repo_url" "$installed_dir"

  return $?
}

update_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"
  local checkout_mode
  checkout_mode=$(get_component_repository_mode "$component")

  if dry_run_git_operation "pull" "$installed_dir"; then
    return 0
  fi

  if [ ! -d "$installed_dir" ]; then
    ui_warning "$(_f "Repository for '%s' not found. Cloning to .downloads/%s instead." "$component" "$component")"
    clone_component_repository "$component"
    return $?
  fi

  if [ "$checkout_mode" = "tag" ]; then
    ui_info "$(_f "Repository for '%s' is pinned to a tag. Re-cloning to ensure correct version." "$component")"
    clone_component_repository "$component"
    return $?
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Updating repository for component: %s" "$component")"
  fi

  local checkout_ref
  checkout_ref=$(get_component_repository_ref "$component")

  local update_message="$(_f "Updating repository for '%s'..." "$component")"

  ui_spinner "$update_message" \
    sh -c "

      cd '$installed_dir' || exit 1
      git fetch origin '$checkout_ref' || exit 1
      git checkout -B '$checkout_ref' \"origin/$checkout_ref\" >/dev/null 2>&1 || exit 1
      git reset --hard \"origin/$checkout_ref\" || exit 1
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

  if [ ! -f "$component_file" ]; then
    return 0
  fi

  if ! yaml_path_exists "$component_file" ".repository"; then
    return 0
  fi

  local repo_dir="${MEOW_DOWNLOADS_DIR}/${component}"
  local cleanup_successful_status=0

  if [ -d "${repo_dir}/.git" ]; then
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
