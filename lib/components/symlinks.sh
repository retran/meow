#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_SYMLINKS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/symlinks/symlinks.sh"
source "${MEOW}/lib/strings/strings.sh"

# Setup symlinks defined in a component's configuration
setup_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  if [[ ! -d "$symlinks_dir" ]]; then
    return 0
  fi

  local yaml_files=()
  mapfile -t yaml_files < <(find "$symlinks_dir" -name "*.yaml" 2>/dev/null)

  if [[ ${#yaml_files[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(fmt "setting_up_symlinks_for" "$component")"
  fi

  local had_symlinks=false
  local success_count=0
  local error_count=0

  for yaml_file in "${yaml_files[@]}"; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks=true

    if setup_component_symlinks_from_file "$component" "$symlink_name"; then
      ui_verbose_action_success "$(fmt "symlinks_for_configured" "$symlink_name")"
      ((success_count++))
    else
      ui_action_warning "$(fmt "symlinks_setup_failed" "$symlink_name")"
      ((error_count++))
    fi
  done

  if [[ "$had_symlinks" == "true" ]]; then
    if [[ "$MEOW_VERBOSE" != "true" ]]; then
      if [[ $error_count -eq 0 ]]; then
        local config_plural=$([ $success_count -gt 1 ] && echo "s" || echo "")
        ui_indent "$(fmt "symlinks_configuration_checked" "$success_count" "$config_plural")"
      else
        local error_plural=$([ $error_count -gt 1 ] && echo "s" || echo "")
        ui_indent "$(fmt "symlinks_errors_successful" "$error_count" "$error_plural" "$success_count")"
      fi
    else
      if [[ $error_count -eq 0 ]]; then
        ui_action_success "$(fmt "symlinks_configured_successfully" "$success_count")"
      else
        ui_warning "$(fmt "symlinks_configured_with_errors" "$error_count" "$success_count" "$((success_count + error_count))")"
      fi
    fi
  fi
}

# Remove symlinks created by a component and restore their backups
remove_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  if [[ ! -d "$symlinks_dir" ]]; then
    return 0
  fi

  local yaml_files=()
  mapfile -t yaml_files < <(find "$symlinks_dir" -name "*.yaml" 2>/dev/null)

  if [[ ${#yaml_files[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(fmt "symlinks_removing_for_component" "$component")"
  fi

  local had_symlinks=false
  local success_count=0
  local error_count=0

  for yaml_file in "${yaml_files[@]}"; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks=true

    if remove_component_symlinks_from_file "$component" "$symlink_name"; then
      ui_verbose_action_success "$(fmt "symlinks_for_removed_successfully" "$symlink_name")"
      ((success_count++))
    else
      ui_warning "$(fmt "symlinks_remove_failed_for" "$symlink_name")"
      ((error_count++))
    fi
  done

  if [[ "$had_symlinks" == "true" ]]; then
    if [[ $error_count -eq 0 ]]; then
      ui_action_success "$(fmt "symlinks_removed_successfully" "$success_count")"
    else
      ui_warning "$(fmt "symlinks_removed_with_errors" "$error_count" "$success_count" "$((success_count + error_count))")"
    fi
  fi
}

# Remove symlinks from a specific symlink file and restore backups
remove_component_symlinks_from_file() {
  local component="$1"
  local symlink_name="$2"
  local symlinks_file="${MEOW_COMPONENTS_DIR}/${component}/symlinks/${symlink_name}.yaml"

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
              dry_run_ui_info "$(fmt "dry_run_would_remove_symlink" "$expanded_target")"
            elif [[ -e "$expanded_target" ]]; then
              dry_run_ui_info "$(fmt "dry_run_would_skip_non_symlink" "$expanded_target")"
            else
              dry_run_ui_info "$(fmt "dry_run_would_skip_non_existent" "$expanded_target")"
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
    ui_action_error "$(fmt "symlinks_yq_required")"
    return 1
  fi

  if [[ ! -f "$symlinks_file" ]]; then
    ui_warning "$(fmt "symlinks_file_not_found" "$symlink_name" "$symlinks_file")"
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yq 'length' "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [[ "$num_symlinks" -eq 0 ]]; then
    ui_warning "$(fmt "symlinks_none_defined" "$symlinks_file")"
    return 0
  fi

  local i=0
  while [[ $i -lt $num_symlinks ]]; do
    local target_path
    target_path=$(yq ".[$i].target" "$symlinks_file")

    if [[ "$target_path" == "null" ]]; then
      ui_warning "$(fmt "symlinks_missing_target_key" "$i" "$symlinks_file")"
      ((failed_count++))
      ((i++))
      continue
    fi

    local expanded_target
    expanded_target=$(expand_path "$target_path")

    debug "Processing symlink removal: $expanded_target"
    ((processed_count++))

    if [[ -L "$expanded_target" ]]; then
      if rm "$expanded_target"; then
        debug "Removed symlink: $expanded_target"

        local backup_pattern="${expanded_target}.backup.*"
        local backup_files=()
        mapfile -t backup_files < <(ls -t $backup_pattern 2>/dev/null)

        if [[ ${#backup_files[@]} -gt 0 ]]; then
          local latest_backup="${backup_files[0]}"
          if mv "$latest_backup" "$expanded_target"; then
            ui_verbose_info "$(basename "$expanded_target") (restored from backup)"
            ((restored_count++))
          else
            ui_warning "$(fmt "symlinks_failed_restore_backup" "$(basename "$expanded_target")")"
            ((failed_count++))
          fi
        else
          ui_verbose_info "$(basename "$expanded_target") (removed, no backup found)"
        fi
      else
        ui_action_error "$(fmt "symlinks_failed_remove" "$expanded_target")"
        ((failed_count++))
      fi
    elif [[ -e "$expanded_target" ]]; then
      ui_verbose_info "$(basename "$expanded_target") (not a symlink, skipping)"
    else
      ui_verbose_info "$(basename "$expanded_target") (does not exist, skipping)"
    fi

    ((i++))
  done

  if [[ $failed_count -eq 0 ]]; then
    if [[ $restored_count -gt 0 ]]; then
      ui_action_success "$(fmt "symlinks_processed_with_backup" "$processed_count" "$restored_count")"
    else
      ui_action_success "$(fmt "symlinks_processed_no_backup" "$processed_count")"
    fi
    return 0
  else
    ui_action_error "$(fmt "symlinks_failed_to_process" "$failed_count" "$processed_count")"
    return 1
  fi
}
