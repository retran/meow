#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_PRESET_SYSTEM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PRESET_SYSTEM_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/colors.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/components/components.sh"

# Check if preset is installed
is_preset_installed() {
  local preset="$1"
  [[ -L "${MEOW_INSTALLED_PRESETS_DIR}/${preset}" ]]
}

# Check if preset is available on current platform
is_preset_available() {
  local preset="$1"
  local preset_file
  preset_file=$(get_preset_file "$preset")

  [[ -f "$preset_file" ]] || return 1

  local platforms
  platforms=$(yq eval '.platforms[]?' "$preset_file" 2>/dev/null)

  if [[ -n "$platforms" && "$platforms" != "null" ]]; then
    local current_platform=""
    if [[ "$IS_MACOS" == "true" ]]; then
      current_platform="macos"
    elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
      current_platform="linux"
    elif [[ "$IS_ALPINE" == "true" ]]; then
      current_platform="linux"
    elif [[ "$IS_ARCH" == "true" ]]; then
      current_platform="linux"
    fi

    if [[ -n "$current_platform" ]]; then
      local platform_supported=false
      while IFS= read -r platform; do
        [[ -n "$platform" && "$platform" != "null" ]] || continue
        if [[ "$platform" == "$current_platform" ]]; then
          platform_supported=true
          break
        fi
      done < <(printf '%s\n' "$platforms")

      [[ "$platform_supported" == true ]] || return 1
    fi
  fi

  return 0
}

# Get preset file path
get_preset_file() {
  local preset="$1"
  echo "${MEOW_PRESETS_DIR}/${preset}/preset.yaml"
}

# Get required components for a preset
get_preset_required_components() {
  local preset="$1"
  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [[ ! -f "$preset_file" ]]; then
    return 1
  fi

  yq eval '.required[]?' "$preset_file" 2>/dev/null | grep -v "^null$" || true
}

# Collect all components and dependencies for preset installation in topological order
collect_preset_components_for_installation() {
  local preset="$1"
  local -n result_ref="$2"
  local all_components=()

  local preset_components
  preset_components=$(get_preset_required_components "$preset")

  if [[ -n "$preset_components" ]]; then
    while IFS= read -r component; do
      [[ -z "$component" ]] && continue
      all_components+=("$component")
    done <<<"$preset_components"
  fi

  local collected_components=()
  for component in "${all_components[@]}"; do
    local component_and_deps=()
    collect_all_dependencies_for_installation "$component" component_and_deps

    for comp in "${component_and_deps[@]}"; do
      local already_added=false
      for existing in "${collected_components[@]}"; do
        if [[ "$existing" == "$comp" ]]; then
          already_added=true
          break
        fi
      done
      if [[ "$already_added" == "false" ]]; then
        collected_components+=("$comp")
      fi
    done
  done

  local sorted_components=()
  topological_sort_for_installation collected_components sorted_components
  result_ref=("${sorted_components[@]}")
}

# Install a preset (install all required components)
install_preset() {
  local preset="$1"

  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [[ ! -f "$preset_file" ]]; then
    ui_error "$(format_template_message "preset_not_found" "$preset")"
    return 1
  fi

  if ! is_preset_available "$preset"; then
    ui_error "$(format_template_message "preset_not_available_platform" "$preset")"
    return 1
  fi

  if is_preset_installed "$preset"; then
    ui_warning "$(format_template_message "preset_already_installed" "$preset")"
    return 0
  fi

  ui_title "$(format_template_message "installing_preset" "$preset")"

  local installation_order=()
  collect_preset_components_for_installation "$preset" installation_order

  if [[ ${#installation_order[@]} -eq 0 ]]; then
    ui_info "$(get_static_message "no_components_to_install_preset")"
  else
    local preset_components
    preset_components=$(get_preset_required_components "$preset")
    local preset_components_array=()

    if [[ -n "$preset_components" ]]; then
      while IFS= read -r component; do
        [[ -z "$component" ]] && continue
        preset_components_array+=("$component")
      done <<<"$preset_components"
    fi

    local components_to_install=()
    for comp in "${installation_order[@]}"; do
      if ! is_component_installed "$comp"; then
        components_to_install+=("$comp")
      fi
    done

    ui_action_start "$(format_template_message "will_install_preset_components" "${#preset_components_array[@]}")"
    if [[ ${#components_to_install[@]} -gt 0 ]]; then
      ui_indent "$(format_template_message "total_components_to_install" "${#components_to_install[@]}")"

      if [[ "$MEOW_VERBOSE" == "true" ]]; then
        ui_step_header "$(get_static_message "installation_order")"
        for comp in "${installation_order[@]}"; do
          local status=""
          if is_component_installed "$comp"; then
            status=" (already installed)"
          fi

          local is_preset_component=false
          for preset_comp in "${preset_components_array[@]}"; do
            if [[ "$preset_comp" == "$comp" ]]; then
              is_preset_component=true
              break
            fi
          done

          if [[ "$is_preset_component" == "true" ]]; then
            ui_verbose_info "  ➤ $comp (preset component)$status"
          else
            ui_verbose_info "  ↪ $comp (dependency)$status"
          fi
        done
      else
        local deps_list=""
        local preset_comp_list=""
        for comp in "${components_to_install[@]}"; do
          local is_preset_component=false
          for preset_comp in "${preset_components_array[@]}"; do
            if [[ "$preset_comp" == "$comp" ]]; then
              is_preset_component=true
              break
            fi
          done

          if [[ "$is_preset_component" == "true" ]]; then
            if [[ -z "$preset_comp_list" ]]; then
              preset_comp_list="$comp"
            else
              preset_comp_list="$preset_comp_list, $comp"
            fi
          else
            if [[ -z "$deps_list" ]]; then
              deps_list="$comp"
            else
              deps_list="$deps_list, $comp"
            fi
          fi
        done

        if [[ -n "$preset_comp_list" ]]; then
          ui_indent "$(format_template_message "preset_components_list" "$preset_comp_list")"
        fi
        if [[ -n "$deps_list" ]]; then
          ui_indent "$(format_template_message "dependencies_list" "$deps_list")"
        fi
      fi
    else
      ui_indent "$(get_static_message 'all_components_installed')"
    fi

    _initialize_session || {
      ui_error "$(get_static_message 'session_init_failed')"
      return 1
    }

    declare -ga MEOW_INSTALLING_COMPONENTS=()

    local install_success=true
    for component in "${installation_order[@]}"; do
      if ! _install_single_component "$component" false false; then
        ui_error "$(format_template_message 'component_install_failed' "$component")"
        install_success=false
        break
      fi
    done

    _finalize_session
    unset MEOW_INSTALLING_COMPONENTS

    if [[ "$install_success" != "true" ]]; then
      ui_error "$(get_static_message "failed_install_required_components")"
      return 1
    fi
  fi

  if is_dry_run; then
    dry_run_file_operation "create_symlink" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}" "${MEOW_PRESETS_DIR}/${preset}"
  else
    mkdir -p "$MEOW_INSTALLED_PRESETS_DIR"
    ln -s "${MEOW_PRESETS_DIR}/${preset}" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}"
  fi

  return 0
}

# Update a preset (update all installed components from the preset)
update_preset() {
  local preset="$1"

  if ! is_preset_installed "$preset"; then
    ui_warning "$(format_template_message "preset_not_installed" "$preset")"
    return 1
  fi

  ui_header "$(format_template_message "updating_preset" "$preset")"

  ui_step_header "$(get_static_message "updating_required_components")"
  local required_components
  required_components=$(get_preset_required_components "$preset")

  if [[ -n "$required_components" ]]; then
    local components_to_update=()
    while IFS= read -r component; do
      [[ -z "$component" ]] && continue
      if is_component_installed "$component"; then
        components_to_update+=("$component")
      else
        ui_info "$(format_template_message "required_component_not_installed" "$component")"
      fi
    done <<<"$required_components"

    if [[ ${#components_to_update[@]} -gt 0 ]]; then
      ui_info "Updating ${#components_to_update[@]} installed components: ${components_to_update[*]}"
      update_component "${components_to_update[@]}"
    fi
  fi

  ui_action_success "Preset '$preset' updated successfully"
  return 0
}

# Get list of all installed components
get_all_installed_components() {
  local installed_components=()
  local components_dir="${MEOW}/.installed/components"

  if [[ ! -d "$components_dir" ]]; then
    return 0
  fi

  for component_symlink in "$components_dir"/*; do
    [[ -L "$component_symlink" ]] || continue
    local component_name
    component_name=$(basename "$component_symlink")
    installed_components+=("$component_name")
  done

  if [[ ${#installed_components[@]} -gt 0 ]]; then
    printf '%s\n' "${installed_components[@]}"
  fi
}

# Update all installed components
update_all_installed_components() {
  local components
  components=($(get_all_installed_components))

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_info "$(get_static_message "no_components_currently_installed")"
    return 0
  fi

  ui_header "Updating all installed components"
  ui_info "$(format_template_message "found_installed_components" "${#components[@]}" "${components[*]}")"

  source "${MEOW}/lib/components/components.sh"
  update_component "${components[@]}"
}

# List all available presets
list_presets() {
  ui_header "$(get_static_message "available_presets")"

  for preset_dir in "${MEOW_PRESETS_DIR}"/*; do
    [[ ! -d "$preset_dir" ]] && continue

    local preset_name
    preset_name=$(basename "$preset_dir")
    local preset_file="${preset_dir}/preset.yaml"

    if [[ -f "$preset_file" ]]; then
      local description
      description=$(yq eval '.description // ""' "$preset_file" 2>/dev/null)

      local status="  "
      if is_preset_installed "$preset_name"; then
        status="✓ "
      elif ! is_preset_available "$preset_name"; then
        status="❌ "
      fi

      local availability=""
      if ! is_preset_available "$preset_name"; then
        availability=" [UNAVAILABLE]"
      fi

      ui_info "${status}${preset_name} - ${description}${availability}"
    fi
  done
}

# Uninstall a preset and its safe dependencies
uninstall_preset() {
  local preset="$1"
  local force_flag="${2:-}"

  if ! is_preset_installed "$preset"; then
    ui_error "$(format_template_message "preset_not_installed" "$preset")"
    return 1
  fi

  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [[ ! -f "$preset_file" ]]; then
    ui_error "$(format_template_message "preset_not_found" "$preset")"
    return 1
  fi

  ui_action_start "$(format_template_message "uninstalling_preset" "$preset")"

  local preset_components
  preset_components=$(get_preset_required_components "$preset")
  local preset_components_array=()

  if [[ -n "$preset_components" ]]; then
    while IFS= read -r component; do
      [[ -z "$component" ]] && continue
      if is_component_installed "$component"; then
        preset_components_array+=("$component")
      fi
    done <<<"$preset_components"
  fi

  if [[ ${#preset_components_array[@]} -eq 0 ]]; then
    ui_info "$(format_template_message "no_components_to_uninstall_preset" "$preset")"
  else
    local preset_name="$preset"

    local multiple_uninstall_order=()
    collect_multiple_components_for_uninstall "${preset_components_array[@]}" --filter-source --exclude-preset="$preset_name"

    if [[ ${#multiple_uninstall_order[@]} -gt 0 ]]; then
      local args=("${multiple_uninstall_order[@]}")
      if [[ "$force_flag" == "--force" ]]; then
        args+=("--force")
      fi
      args+=("--exclude-preset=$preset_name")

      if ! uninstall_component "${args[@]}"; then
        ui_error "$(format_template_message "preset_uninstall_failed" "$preset_name")"
        return 1
      fi
    else
      ui_info "$(format_template_message "preset_no_safe_components_to_uninstall" "$preset_name")"
    fi
  fi

  remove_preset_tracking "$preset"

  ui_success "$(format_template_message "preset_uninstalled_successfully" "$preset")"
  return 0
}

# Remove preset tracking (symlink)
remove_preset_tracking() {
  local preset="$1"

  if is_dry_run; then
    dry_run_file_operation "remove_symlink" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}"
  else
    rm -rf "${MEOW_INSTALLED_PRESETS_DIR:?}/${preset}"
  fi
}

# Uninstall all installed presets
uninstall_all_presets() {
  local force_flag="${1:-}"
  local installed_presets=()

  for preset_symlink in "${MEOW_INSTALLED_PRESETS_DIR}"/*; do
    [[ -L "$preset_symlink" ]] || continue
    local preset_name
    preset_name=$(basename "$preset_symlink")
    installed_presets+=("$preset_name")
  done

  if [[ ${#installed_presets[@]} -eq 0 ]]; then
    ui_info "$(get_static_message "no_presets_installed")"
    return 0
  fi

  ui_action_start "$(format_template_message "uninstalling_all_presets" "${#installed_presets[@]}")"

  local all_preset_components=()
  for preset in "${installed_presets[@]}"; do
    local preset_components
    preset_components=$(get_preset_required_components "$preset")

    while IFS= read -r component; do
      [[ -n "$component" && "$component" != "null" ]] || continue

      local already_added=false
      for existing in "${all_preset_components[@]}"; do
        if [[ "$existing" == "$component" ]]; then
          already_added=true
          break
        fi
      done
      if [[ "$already_added" == "false" ]]; then
        all_preset_components+=("$component")
      fi
    done < <(printf '%s\n' "$preset_components")
  done

  if [[ ${#all_preset_components[@]} -eq 0 ]]; then
    ui_info "$(format_template_message "no_components_to_uninstall_all_presets")"
    for preset in "${installed_presets[@]}"; do
      remove_preset_tracking "$preset"
    done
    ui_success "$(get_static_message "all_presets_uninstalled_successfully")"
    return 0
  fi

  local multiple_uninstall_order=()
  collect_multiple_components_for_uninstall "${all_preset_components[@]}" --filter-source --skip-preset-checks

  if [[ ${#multiple_uninstall_order[@]} -gt 0 ]]; then
    local args=("${multiple_uninstall_order[@]}")
    if [[ "$force_flag" == "--force" ]]; then
      args+=("--force")
    fi
    args+=("--skip-preset-checks")

    if ! uninstall_component "${args[@]}"; then
      ui_error "$(get_static_message "all_presets_uninstall_failed")"
      return 1
    fi
  else
    ui_info "$(format_template_message "no_safe_components_to_uninstall_all_presets")"
  fi

  for preset in "${installed_presets[@]}"; do
    remove_preset_tracking "$preset"
  done

  ui_success "$(get_static_message "all_presets_uninstalled_successfully")"
  return 0
}
