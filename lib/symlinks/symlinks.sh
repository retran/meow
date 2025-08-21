#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"

SYMLINKS_DIR="${MEOW}/symlinks"

expand_path() {
  local path="$1"
  eval echo "$path"
}

create_symlink() {
  local source="$1"
  local target="$2"
  local expanded_source
  local expanded_target

  expanded_source=$(expand_path "$source")
  expanded_target=$(expand_path "$target")

  debug "Attempting to create symlink: $expanded_target -> $expanded_source"

  if [[ ! -e "$expanded_source" ]]; then
    warning "Source $expanded_source does not exist. Skipping symlink for $(basename "$expanded_target")"
    return 0
  fi

  if mkdir -p "$(dirname "$expanded_target")"; then
    debug "Parent directory for $expanded_target ensured."
  else
    error_msg "Failed to create parent directory for $expanded_target."
    return 1
  fi

  if [[ -L "$expanded_target" && "$(readlink "$expanded_target")" == "$expanded_source" ]]; then
    success_tick_msg "$(basename "$expanded_target") (already correct)"
    return 0
  fi

  if [[ -e "$expanded_target" || -L "$expanded_target" ]]; then
    if [[ -L "$expanded_target" ]]; then
      debug "Replacing existing symlink at $expanded_target"
      if rm "$expanded_target"; then
        debug "Removed existing symlink at $expanded_target"
      else
        error_msg "Failed to remove existing symlink at $expanded_target."
        return 1
      fi
    else
      local backup_path
      backup_path="${expanded_target}.backup.$(date +%Y%m%d_%H%M%S)"
      debug "Creating backup of existing file: $expanded_target -> $backup_path"
      if mv "$expanded_target" "$backup_path"; then
        info "$(basename "$expanded_target") (backed up to $(basename "$backup_path"))"
      else
        error_msg "Failed to backup existing file at $expanded_target."
        return 1
      fi
    fi
  fi

  if ln -s "$expanded_source" "$expanded_target"; then
    success_tick_msg "$(basename "$expanded_target") (created)"
    return 0
  else
    error_msg "Failed to create symlink: $expanded_target -> $expanded_source"
    return 1
  fi
}

setup_symlinks() {
  local category="$1"
  local symlinks_file="${SYMLINKS_DIR}/${category}.yaml"
  local failed_count=0
  local processed_count=0
  local start_time end_time duration

  start_time=$(date +%s)
  step_header "Setting up symlinks ($category)"

  if ! command -v yq >/dev/null 2>&1; then
    error_msg "yq is required to parse symlink configuration. Please install yq."
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    warning "No symlinks file found for category '$category' at $symlinks_file"
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yq 'length' "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [[ "$num_symlinks" -eq 0 ]]; then
    info "No symlinks defined in $symlinks_file."
    success_tick_msg "Symlink setup for '$category' complete (0 symlinks)."
    return 0
  fi

  for ((i = 0; i < num_symlinks; i++)); do
    local source target os
    source=$(yq -r ".[$i].source" "$symlinks_file")
    target=$(yq -r ".[$i].target" "$symlinks_file")
    os=$(yq -r ".[$i].os // \"any\"" "$symlinks_file")

    local should_create=false
    if [[ "$os" == "any" ]]; then
      should_create=true
    elif [[ "$os" == "macos" && "$IS_MACOS" == "true" ]]; then
      should_create=true
    elif [[ "$os" == "linux" && "$IS_DEBIAN_BASED" == "true" ]]; then
      should_create=true
    fi

    if [[ "$should_create" == "true" ]]; then
      processed_count=$((processed_count + 1))
      if ! create_symlink "$source" "$target"; then
        failed_count=$((failed_count + 1))
      fi
    else
      debug "Skipping symlink for $(basename "$target") due to OS mismatch (required: '${os}')"
    fi
  done

  if [[ $processed_count -gt 0 ]]; then
    info "($processed_count symlinks processed for this OS)"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    success_tick_msg "Symlink setup for '$category' completed (${duration}s)"
    return 0
  else
    error_msg "Symlink setup for '$category' failed with $failed_count failure(s) (${duration}s)"
    return 1
  fi
}

debug() {
  if [ "${DEBUG:-0}" = "1" ]; then
    # shellcheck disable=SC2005
    printf '%s\n' "${MAGENTA}DEBUG:${RESET} $*" >&2
  fi
}

list_backups() {
  local target_pattern="${1:-}"

  if [[ -z "$target_pattern" ]]; then
    echo "Listing all symlink backups:"
    local found=false
    for backup_file in "$HOME"/.*.backup.*; do
      if [[ -f "$backup_file" ]]; then
        local original_file="${backup_file%.backup.*}"
        local backup_timestamp="${backup_file##*.backup.}"
        echo "  $(basename "$original_file") -> $(basename "$backup_file") (created: $backup_timestamp)"
        found=true
      fi
    done
    if [[ "$found" == false ]]; then
      echo "  No symlink backups found"
    fi
  else
    echo "Listing backups for pattern: $target_pattern"
    local found=false
    for backup_file in "$HOME"/*"${target_pattern}"*.backup.*; do
      if [[ -f "$backup_file" ]]; then
        local original_file="${backup_file%.backup.*}"
        local backup_timestamp="${backup_file##*.backup.}"
        echo "  $(basename "$original_file") -> $(basename "$backup_file") (created: $backup_timestamp)"
        found=true
      fi
    done
    if [[ "$found" == false ]]; then
      echo "  No backups found for pattern: $target_pattern"
    fi
  fi
}

restore_backup() {
  local backup_file="$1"

  if [[ ! -f "$backup_file" && ! "$backup_file" = /* ]]; then
    backup_file="$HOME/$backup_file"
  fi

  if [[ ! -f "$backup_file" ]]; then
    echo "Backup file not found: $backup_file"
    return 1
  fi

  local original_file="${backup_file%.backup.*}"

  echo "Restoring backup: $(basename "$backup_file") -> $(basename "$original_file")"

  if [[ -e "$original_file" || -L "$original_file" ]]; then
    echo "  Target location already exists, creating backup of current state"
    local current_backup
    current_backup="${original_file}.backup.$(date +%Y%m%d_%H%M%S).current"
    if mv "$original_file" "$current_backup"; then
      echo "  Current state backed up to $(basename "$current_backup")"
    else
      echo "  Failed to backup current state"
      return 1
    fi
  fi

  if mv "$backup_file" "$original_file"; then
    echo "  Successfully restored $(basename "$original_file")"
    return 0
  else
    echo "  Failed to restore backup"
    return 1
  fi
}

# Remove symlinks and restore backups for a category
cleanup_symlinks() {
  local category="$1"
  local symlinks_file="${SYMLINKS_DIR}/${category}.yaml"
  local removed_count=0
  local restored_count=0

  step_header "Cleaning up symlinks ($category)"

  if ! command -v yq >/dev/null 2>&1; then
    error_msg "yq is required to parse symlink configuration. Please install yq."
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    warning "No symlinks file found for category '$category' at $symlinks_file"
    return 0
  fi

  # Parse the YAML file and process each symlink
  while IFS=$'\t' read -r source target; do
    [[ -n "$source" && -n "$target" ]] || continue

    local expanded_target
    expanded_target=$(expand_path "$target")

    # Check if it's a symlink pointing to our source
    if [[ -L "$expanded_target" ]]; then
      local link_target
      link_target=$(readlink "$expanded_target")
      local expanded_source
      expanded_source=$(expand_path "$source")

      if [[ "$link_target" == "$expanded_source" ]]; then
        # Remove the symlink
        if rm "$expanded_target"; then
          info "$(basename "$expanded_target") (symlink removed)"
          removed_count=$((removed_count + 1))

          # Look for and restore backup
          local latest_backup
          latest_backup=$(find "$(dirname "$expanded_target")" -name "$(basename "$expanded_target").backup.*" -type f 2>/dev/null | sort -r | head -n 1)

          if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
            if mv "$latest_backup" "$expanded_target"; then
              success_tick_msg "$(basename "$expanded_target") (restored from backup)"
              restored_count=$((restored_count + 1))
            else
              warning "Failed to restore backup for $(basename "$expanded_target")"
            fi
          fi
        else
          error_msg "Failed to remove symlink: $expanded_target"
        fi
      fi
    fi
  done < <(yq eval '.[] | [.source, .target] | @tsv' "$symlinks_file" 2>/dev/null)

  if [[ $removed_count -eq 0 ]]; then
    info "No symlinks found to remove"
  else
    success_tick_msg "Removed $removed_count symlinks"
    if [[ $restored_count -gt 0 ]]; then
      success_tick_msg "Restored $restored_count files from backup"
    fi
  fi
}
