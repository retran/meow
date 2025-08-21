#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/symlinks/symlinks.sh"

# Setup symlinks defined in a component's configuration
# Args:
#   $1 - component name
setup_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  # Check if symlinks directory exists
  if [[ ! -d "$symlinks_dir" ]]; then
    return 0
  fi

  # Check if there are any .yaml files in the symlinks directory
  local yaml_files=()
  mapfile -t yaml_files < <(find "$symlinks_dir" -name "*.yaml" 2>/dev/null)

  if [[ ${#yaml_files[@]} -eq 0 ]]; then
    return 0
  fi

  # Show symlinks section header only in verbose mode
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Setting up symlinks for component: $component"
  fi

  local had_symlinks=false
  local success_count=0
  local error_count=0

  for yaml_file in "${yaml_files[@]}"; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks=true

    if setup_component_symlinks_from_file "$component" "$symlink_name"; then
      verbose_success_tick_msg "Symlinks for '$symlink_name' configured successfully"
      ((success_count++))
    else
      warning_msg "Failed to setup symlinks for '$symlink_name'"
      ((error_count++))
    fi
  done

  if [[ "$had_symlinks" == "true" ]]; then
    if [[ "$MEOW_VERBOSE" != "true" ]]; then
      # Show compact summary in non-verbose mode
      if [[ $error_count -eq 0 ]]; then
        indent_msg "Symlinks: ✓ $success_count configuration$([ $success_count -gt 1 ] && echo "s") checked, no changes needed"
      else
        indent_msg "Symlinks: ✗ $error_count error$([ $error_count -gt 1 ] && echo "s"), $success_count successful"
      fi
    else
      # Show detailed summary in verbose mode
      if [[ $error_count -eq 0 ]]; then
        success_tick_msg "Component symlinks configured successfully ($success_count symlink files)"
      else
        warning "Component symlinks configured with $error_count errors ($success_count/$((success_count + error_count)) symlink files)"
      fi
    fi
  fi
}

# Remove symlinks created by a component and restore their backups
# Args: $1 - component name
remove_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  # Check if symlinks directory exists
  if [[ ! -d "$symlinks_dir" ]]; then
    return 0
  fi

  # Check if there are any .yaml files in the symlinks directory
  local yaml_files=()
  mapfile -t yaml_files < <(find "$symlinks_dir" -name "*.yaml" 2>/dev/null)

  if [[ ${#yaml_files[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Removing symlinks for component: $component"
  fi

  local had_symlinks=false
  local success_count=0
  local error_count=0

  for yaml_file in "${yaml_files[@]}"; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks=true

    if remove_component_symlinks_from_file "$component" "$symlink_name"; then
      verbose_success_tick_msg "Symlinks for '$symlink_name' removed successfully"
      ((success_count++))
    else
      warning "Failed to remove symlinks for '$symlink_name'"
      ((error_count++))
    fi
  done

  if [[ "$had_symlinks" == "true" ]]; then
    if [[ $error_count -eq 0 ]]; then
      success_tick_msg "Component symlinks removed successfully ($success_count symlink files)"
    else
      warning "Component symlinks removed with $error_count errors ($success_count/$((success_count + error_count)) symlink files)"
    fi
  fi
}

# Remove symlinks from a specific symlink file and restore backups
# Args:
#   $1 - component name
#   $2 - symlink file name (without .yaml extension)
remove_component_symlinks_from_file() {
  local component="$1"
  local symlink_name="$2"
  local symlinks_file="${MEOW_COMPONENTS_DIR}/${component}/symlinks/${symlink_name}.yaml"
  
  # Handle dry-run mode
  if is_dry_run; then
    if [[ -f "$symlinks_file" ]]; then
      local num_symlinks
      num_symlinks=$(yq 'length' "$symlinks_file" 2>/dev/null || echo "0")
      if [[ "$num_symlinks" =~ ^[0-9]+$ ]] && [[ "$num_symlinks" -gt 0 ]]; then
        local i=0
        while [[ $i -lt $num_symlinks ]]; do
          local target_path
          target_path=$(yq ".[$i].target" "$symlinks_file" 2>/dev/null)
          if [[ "$target_path" != "null" && -n "$target_path" ]]; then
            local expanded_target
            expanded_target=$(expand_path "$target_path")
            if [[ -L "$expanded_target" ]]; then
              dry_run_info "Would remove symlink: $expanded_target"
            elif [[ -e "$expanded_target" ]]; then
              dry_run_info "Would skip non-symlink: $expanded_target"
            else
              dry_run_info "Would skip non-existent: $expanded_target"
            fi
          fi
          ((i++))
        done
      fi
    fi
    return 0
  fi
  
  local failed_count=0
  local processed_count=0
  local restored_count=0

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
    warning "No symlinks defined in $symlinks_file"
    return 0
  fi

  local i=0
  while [[ $i -lt $num_symlinks ]]; do
    local target_path
    target_path=$(yq ".[$i].target" "$symlinks_file")

    if [[ "$target_path" == "null" ]]; then
      warning "Missing 'target' key in symlink entry $i of $symlinks_file"
      ((failed_count++))
      ((i++))
      continue
    fi

    local expanded_target
    expanded_target=$(expand_path "$target_path")

    debug "Processing symlink removal: $expanded_target"
    ((processed_count++))

    # Check if the target is a symlink (our symlink)
    if [[ -L "$expanded_target" ]]; then
      # Remove the symlink
      if rm "$expanded_target"; then
        debug "Removed symlink: $expanded_target"

        # Look for and restore backup
        local backup_pattern="${expanded_target}.backup.*"
        local backup_files=()
        mapfile -t backup_files < <(ls -t $backup_pattern 2>/dev/null)

        if [[ ${#backup_files[@]} -gt 0 ]]; then
          local latest_backup="${backup_files[0]}"
          if mv "$latest_backup" "$expanded_target"; then
            verbose_info "$(basename "$expanded_target") (restored from backup)"
            ((restored_count++))
          else
            warning "Failed to restore backup for $(basename "$expanded_target")"
            ((failed_count++))
          fi
        else
          verbose_info "$(basename "$expanded_target") (removed, no backup found)"
        fi
      else
        error_msg "Failed to remove symlink: $expanded_target"
        ((failed_count++))
      fi
    elif [[ -e "$expanded_target" ]]; then
      # File exists but is not a symlink - probably already restored or modified manually
      verbose_info "$(basename "$expanded_target") (not a symlink, skipping)"
    else
      # File doesn't exist - already removed or never existed
      verbose_info "$(basename "$expanded_target") (does not exist, skipping)"
    fi

    ((i++))
  done

  if [[ $failed_count -eq 0 ]]; then
    if [[ $restored_count -gt 0 ]]; then
      success_tick_msg "Processed $processed_count symlinks ($restored_count restored from backup)"
    else
      success_tick_msg "Processed $processed_count symlinks (no backups to restore)"
    fi
    return 0
  else
    error_msg "Failed to process $failed_count of $processed_count symlinks"
    return 1
  fi
}
