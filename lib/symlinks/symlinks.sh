#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"

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
    if is_dry_run; then
      dry_run_info "Would skip symlink (source does not exist): $expanded_target -> $expanded_source"
      return 0
    fi
    warning_msg "Source $expanded_source does not exist. Skipping symlink for $(basename "$expanded_target")"
    return 0
  fi

  # Check current state and handle dry-run accordingly
  if [[ -L "$expanded_target" && "$(readlink "$expanded_target")" == "$expanded_source" ]]; then
    if is_dry_run; then
      dry_run_info "Symlink already correct: $expanded_target -> $expanded_source"
    else
      verbose_success_tick_msg "$(basename "$expanded_target") (already correct)"
    fi
    return 0
  fi

  # Handle dry-run mode for cases where changes would be made
  if is_dry_run; then
    if [[ -L "$expanded_target" ]]; then
      dry_run_info "Would update symlink: $expanded_target -> $expanded_source"
      dry_run_info "  Current target: $(readlink "$expanded_target")"
    elif [[ -e "$expanded_target" ]]; then
      dry_run_info "Would backup existing file and create symlink: $expanded_target -> $expanded_source"
    else
      dry_run_info "Would create new symlink: $expanded_target -> $expanded_source"
    fi
    return 0
  fi

  if mkdir -p "$(dirname "$expanded_target")"; then
    debug "Parent directory for $expanded_target ensured."
  else
    error_msg "Failed to create parent directory for $expanded_target."
    return 1
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
        verbose_info "$(basename "$expanded_target") (backed up to $(basename "$backup_path"))"
      else
        error_msg "Failed to backup existing file at $expanded_target."
        return 1
      fi
    fi
  fi

  if ln -s "$expanded_source" "$expanded_target"; then
    verbose_success_tick_msg "$(basename "$expanded_target") (created)"
    return 0
  else
    error_msg "Failed to create symlink: $expanded_target -> $expanded_source"
    return 1
  fi
}

setup_component_symlinks_from_file() {
  local component="$1"
  local symlink_name="$2"
  local symlinks_file="${MEOW_COMPONENTS_DIR}/${component}/symlinks/${symlink_name}.yaml"
  local failed_count=0
  local processed_count=0
  local start_time end_time duration

  start_time=$(date +%s)

  if ! command -v yq >/dev/null 2>&1; then
    error_msg "yq is required to parse symlink configuration. Please install yq."
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    warning "No symlinks file found for '$symlink_name' at $symlinks_file"
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yq 'length' "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [[ "$num_symlinks" -eq 0 ]]; then
    info "No symlinks defined in $symlinks_file."
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

  if [[ $processed_count -gt 0 && "$MEOW_VERBOSE" == "true" ]]; then
    info "($processed_count symlinks processed for this OS)"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    verbose_success_tick_msg "Symlinks for '$symlink_name' completed (${duration}s)"
    return 0
  else
    error_msg "Symlinks for '$symlink_name' failed with $failed_count failure(s) (${duration}s)"
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

  # Handle dry-run mode
  if dry_run_file_operation "restore_file" "$original_file" "$backup_file"; then
    return 0
  fi

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
