#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/strings/strings.sh"
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
      dry_run_ui_info "$(fmt "symlink_skip_source_missing" "$expanded_target" "$expanded_source")"
      return 0
    fi
    ui_action_warning "$(fmt "symlink_source_missing" "$expanded_source" "$(basename "$expanded_target")")"
    return 0
  fi

  if [[ -L "$expanded_target" && "$(readlink "$expanded_target")" == "$expanded_source" ]]; then
    if is_dry_run; then
      dry_run_ui_info "$(fmt "symlink_already_correct" "$expanded_target" "$expanded_source")"
    else
      ui_verbose_action_success "$(fmt "already_correct")"
    fi
    return 0
  fi

  if is_dry_run; then
    if [[ -L "$expanded_target" ]]; then
      dry_run_ui_info "$(fmt "symlink_update" "$expanded_target" "$expanded_source")"
      dry_run_ui_info "  $(fmt "symlink_current_target" "$(readlink "$expanded_target")")"
    elif [[ -e "$expanded_target" ]]; then
      dry_run_ui_info "$(fmt "symlink_backup_and_create" "$expanded_target" "$expanded_source")"
    else
      dry_run_ui_info "$(fmt "symlink_create_new" "$expanded_target" "$expanded_source")"
    fi
    return 0
  fi

  if mkdir -p "$(dirname "$expanded_target")"; then
    debug "Parent directory for $expanded_target ensured."
  else
    ui_action_error "$(fmt "symlink_parent_dir_failed" "$expanded_target")"
    return 1
  fi

  if [[ -e "$expanded_target" || -L "$expanded_target" ]]; then
    if [[ -L "$expanded_target" ]]; then
      debug "Replacing existing symlink at $expanded_target"
      if rm "$expanded_target"; then
        debug "Removed existing symlink at $expanded_target"
      else
        ui_action_error "$(fmt "symlink_remove_failed" "$expanded_target")"
        return 1
      fi
    else
      local backup_path
      backup_path="${expanded_target}.backup.$(date +%Y%m%d_%H%M%S)"
      debug "Creating backup of existing file: $expanded_target -> $backup_path"
      if mv "$expanded_target" "$backup_path"; then
        ui_verbose_info "$(fmt "symlink_backed_up" "$(basename "$expanded_target")" "$(basename "$backup_path")")"
      else
        ui_action_error "$(fmt "symlink_backup_failed" "$expanded_target")"
        return 1
      fi
    fi
  fi

  if ln -s "$expanded_source" "$expanded_target"; then
    ui_verbose_action_success "$(fmt "symlink_created" "$(basename "$expanded_target")")"
    return 0
  else
    ui_action_error "$(fmt "symlink_create_failed" "$expanded_target" "$expanded_source")"
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
    ui_action_error "$(fmt "yq_required")"
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    ui_warning "$(fmt "no_symlinks_file" "$symlink_name" "$symlinks_file")"
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yq 'length' "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [[ "$num_symlinks" -eq 0 ]]; then
    ui_info "$(fmt "no_symlinks_defined" "$symlinks_file")"
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
    ui_info "$(fmt "symlinks_processed_count" "$processed_count")"
  fi

  end_time=$(date +%s)
  duration=$((end_time - start_time))

  if [[ $failed_count -eq 0 ]]; then
    ui_verbose_action_success "$(fmt "symlinks_completed" "$symlink_name" "$duration")"
    return 0
  else
    ui_action_error "$(fmt "symlinks_failed" "$symlink_name" "$failed_count" "$duration")"
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
    echo "$(fmt "symlinks_listing_all_backups")"
    local found=false
    for backup_file in "$HOME"/.*.backup.*; do
      if [[ -f "$backup_file" ]]; then
        local original_file="${backup_file%.backup.*}"
        local backup_timestamp="${backup_file##*.backup.}"
        echo "$(fmt "symlinks_backup_entry_simple" "$(basename "$original_file")" "$(basename "$backup_file")" "$backup_timestamp")"
        found=true
      fi
    done
    if [[ "$found" == false ]]; then
      echo "$(fmt "symlinks_no_backups_found")"
    fi
  else
    echo "$(fmt "symlinks_listing_backups_pattern" "$target_pattern")"
    local found=false
    for backup_file in "$HOME"/*"${target_pattern}"*.backup.*; do
      if [[ -f "$backup_file" ]]; then
        local original_file="${backup_file%.backup.*}"
        local backup_timestamp="${backup_file##*.backup.}"
        echo "$(fmt "symlinks_backup_entry" "$(basename "$original_file")" "$(basename "$backup_file")" "$backup_timestamp")"
        found=true
      fi
    done
    if [[ "$found" == false ]]; then
      echo "$(fmt "symlinks_no_backups_for_pattern" "$target_pattern")"
    fi
  fi
}

restore_backup() {
  local backup_file="$1"

  if [[ ! -f "$backup_file" && ! "$backup_file" = /* ]]; then
    backup_file="$HOME/$backup_file"
  fi

  if [[ ! -f "$backup_file" ]]; then
    echo "$(fmt "symlinks_backup_not_found" "$backup_file")"
    return 1
  fi

  local original_file="${backup_file%.backup.*}"

  echo "$(fmt "symlinks_restoring_backup" "$(basename "$backup_file")" "$(basename "$original_file")")"

  if dry_run_file_operation "restore_file" "$original_file" "$backup_file"; then
    return 0
  fi

  if [[ -e "$original_file" || -L "$original_file" ]]; then
    echo "$(fmt "symlinks_target_exists_backup")"
    local current_backup
    current_backup="${original_file}.backup.$(date +%Y%m%d_%H%M%S).current"
    if mv "$original_file" "$current_backup"; then
      echo "$(fmt "symlinks_current_backed_up" "$(basename "$current_backup")")"
    else
      echo "$(fmt "symlinks_backup_current_failed")"
      return 1
    fi
  fi

  if mv "$backup_file" "$original_file"; then
    echo "$(fmt "symlinks_restore_success" "$(basename "$original_file")")"
    return 0
  else
    echo "$(fmt "symlinks_restore_failed")"
    return 1
  fi
}
