#!/usr/bin/env bash

# lib/package/symlinks.sh - Functions for managing symlinks in the dotfiles package

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_SYMLINKS_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

SYMLINKS_DIR="${DOTFILES_DIR}/packages/symlinks"

expand_path() {
  local path="$1"
  eval echo "$path"
}

create_symlink() {
  local source="$1"
  local target="$2"
  local indent_level="${3:-2}"
  local expanded_source
  local expanded_target

  expanded_source=$(expand_path "$source")
  expanded_target=$(expand_path "$target")

  debug "Attempting to create symlink: $expanded_target -> $expanded_source"

  if [[ ! -e "$expanded_source" ]]; then
    indented_warning "$indent_level" "Source $expanded_source does not exist. Skipping symlink for $(basename "$expanded_target")."
    return 1
  fi

  if mkdir -p "$(dirname "$expanded_target")"; then
    debug "Parent directory for $expanded_target ensured."
  else
    indented_error_msg "$indent_level" "Failed to create parent directory for $expanded_target."
    return 1
  fi

  if [[ -L "$expanded_target" && "$(readlink "$expanded_target")" == "$expanded_source" ]]; then
    indented_success_tick_msg "$indent_level" "$(basename "$expanded_target") (already correct)"
    return 0
  fi

  if [[ -e "$expanded_target" || -L "$expanded_target" ]]; then
    if rm -rf "$expanded_target"; then
      debug "Removed existing item at $expanded_target"
    else
      indented_error_msg "$indent_level" "Failed to remove existing item at $expanded_target."
      return 1
    fi
  fi

  if ln -s "$expanded_source" "$expanded_target"; then
    indented_success_tick_msg "$indent_level" "$(basename "$expanded_target") (created)"
    return 0
  else
    indented_error_msg "$indent_level" "Failed to create symlink: $expanded_target -> $expanded_source"
    return 1
  fi
}

setup_symlinks() {
  local category="$1"
  local indent_level="${2:-1}"
  local symlinks_file="${SYMLINKS_DIR}/${category}.yaml"
  local failed_count=0
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "$indent_level" "Setting up symlinks ($category)"

  if ! command -v yq &>/dev/null; then
    indented_error_msg "$((indent_level+1))" "yq is required to parse symlink configuration. Please install yq (e.g., brew install yq)."
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    indented_warning "$((indent_level+1))" "No symlinks file found for category '$category' at $symlinks_file."
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yq 'length' "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [[ "$num_symlinks" -eq 0 ]]; then
    indented_info "$((indent_level+1))" "No symlinks defined in $symlinks_file."
    success_tick_msg "$indent_level" "Symlink setup for '$category' complete (0 symlinks)."
    return 0
  fi

  local processed_symlinks_basenames=()
  local source target

  for ((i=0; i<num_symlinks; i++)); do
    source=$(yq -r ".[$i].source" "$symlinks_file")
    target=$(yq -r ".[$i].target" "$symlinks_file")

    if create_symlink "$source" "$target" $((indent_level+1)); then
      processed_symlinks_basenames+=("$(basename "$target")")
    else
      failed_count=$((failed_count + 1))
    fi
  done

  local total_processed=${#processed_symlinks_basenames[@]}

  if [[ $total_processed -gt 0 ]]; then
    indented_info "$((indent_level+1))" "($total_processed symlinks created/verified for $category)"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    success_tick_msg "$indent_level" "Symlink setup for '$category' completed (${duration}s)"
    return 0
  else
    indented_error_msg "$indent_level" "Symlink setup for '$category' failed with $failed_count failure(s) (${duration}s)"
    return 1
  fi
}

debug() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "$(indent 0)${MAGENTA}DEBUG:${RESET} $*" >&2
  fi
}
