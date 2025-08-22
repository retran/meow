#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_OPERATIONS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_OPERATIONS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/strings/strings.sh"

source "${MEOW}/lib/components/core.sh"
source "${MEOW}/lib/components/packages.sh"
source "${MEOW}/lib/components/repository.sh"
source "${MEOW}/lib/components/dependencies.sh"
source "${MEOW}/lib/components/symlinks.sh"

# Collect all components and dependencies for multiple component installation in topological order
collect_multiple_components_for_installation() {
  local components_array=("$@")
  local -n result_ref="multiple_installation_order"
  local all_components=()

  local collected_components=()
  for component in "${components_array[@]}"; do
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

# Public wrapper for installing components - handles session management
install_component() {
  local components=()
  local is_manual="true"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --manual)
        is_manual="true"
        shift
        ;;
      --auto)
        is_manual="false"
        shift
        ;;
      *)
        components+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_error "$(get_static_message 'no_components_specified_install')"
    return 1
  fi

  local multiple_installation_order=()
  collect_multiple_components_for_installation "${components[@]}"

  if [[ ${#multiple_installation_order[@]} -eq 0 ]]; then
    ui_info "$(get_static_message 'no_components_to_install')"
    return 0
  fi

  local components_to_install=()
  for comp in "${multiple_installation_order[@]}"; do
    if ! is_component_installed "$comp"; then
      components_to_install+=("$comp")
    fi
  done

  local plural_suffix=$([ ${#components[@]} -gt 1 ] && echo "s" || echo "")
  ui_action_start "$(format_template_message "components_install_count" "${#components[@]}" "$plural_suffix")"
  if [[ ${#components_to_install[@]} -gt 0 ]]; then
    ui_indent "$(format_template_message "total_components_install" "${#components_to_install[@]}")"

    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      ui_step_header "$(get_static_message 'installation_order')"
      for comp in "${multiple_installation_order[@]}"; do
        local status=""
        if is_component_installed "$comp"; then
          status=" (already installed)"
        fi

        local is_requested_component=false
        for requested_comp in "${components[@]}"; do
          if [[ "$requested_comp" == "$comp" ]]; then
            is_requested_component=true
            break
          fi
        done

        if [[ "$is_requested_component" == "true" ]]; then
          ui_verbose_info "  ➤ $comp (requested component)$status"
        else
          ui_verbose_info "  ↪ $comp (dependency)$status"
        fi
      done
    else
      local deps_list=""
      local requested_comp_list=""
      for comp in "${components_to_install[@]}"; do
        local is_requested_component=false
        for requested_comp in "${components[@]}"; do
          if [[ "$requested_comp" == "$comp" ]]; then
            is_requested_component=true
            break
          fi
        done

        if [[ "$is_requested_component" == "true" ]]; then
          if [[ -z "$requested_comp_list" ]]; then
            requested_comp_list="$comp"
          else
            requested_comp_list="$requested_comp_list, $comp"
          fi
        else
          if [[ -z "$deps_list" ]]; then
            deps_list="$comp"
          else
            deps_list="$deps_list, $comp"
          fi
        fi
      done

      if [[ -n "$requested_comp_list" ]]; then
        ui_indent "$(format_template_message "requested_components" "$requested_comp_list")"
      fi
      if [[ -n "$deps_list" ]]; then
        ui_indent "$(format_template_message "new_dependencies" "$deps_list")"
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
  for component in "${multiple_installation_order[@]}"; do
    local comp_is_manual="$is_manual"
    local comp_is_dependency=false

    local is_requested_component=false
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" == "$component" ]]; then
        is_requested_component=true
        break
      fi
    done

    if [[ "$is_requested_component" == "false" ]]; then
      comp_is_dependency=true
      comp_is_manual="false"
    fi

    if ! _install_single_component "$component" "$comp_is_manual" "$comp_is_dependency"; then
      ui_error "$(format_template_message 'component_install_failed' "$component")"
      install_success=false
      break
    fi
  done

  _finalize_session
  unset MEOW_INSTALLING_COMPONENTS

  if [[ "$install_success" != "true" ]]; then
    return 1
  fi

  return 0
}

# Install a single component without dependencies (used by topologically sorted install)
_install_single_component() {
  local component="$1"
  local is_manual="${2:-true}"
  local is_dependency="${3:-false}"

  local already_installing=false
  for installing_comp in "${MEOW_INSTALLING_COMPONENTS[@]}"; do
    if [[ "$installing_comp" == "$component" ]]; then
      already_installing=true
      break
    fi
  done

  if [[ "$already_installing" == "true" ]]; then
    ui_verbose_info "$(format_template_message "component_already_installing" "$component")"
    return 0
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    ui_error "$(format_template_message 'component_not_found' "$component")"
    return 1
  fi

  if ! is_component_available "$component"; then
    ui_error "$(format_template_message 'component_not_available' "$component")"
    return 1
  fi

  if is_component_installed "$component"; then
    if [[ "$is_manual" == "true" ]] && ! is_component_manually_installed "$component"; then
      mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
      ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}"
      ui_action_success "$(format_template_message 'component_marked_manual' "$component")"
    else
      ui_verbose_info "$(format_template_message 'component_already_installed' "$component")"
    fi
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_component_installing "$component"
  else
    if [[ "$is_dependency" == "true" ]]; then
      ui_dependency "$(format_template_message "component_installing_prefix" "$component")"
    else
      ui_component_installing "$component"
    fi
  fi

  MEOW_INSTALLING_COMPONENTS+=("$component")

  export MEOW_COMPONENT_MANUAL_INSTALL="$is_manual"
  if ! install_component_packages "$component"; then
    ui_error "$(format_template_message 'component_packages_failed' "$component")"
    return 1
  fi

  install_component_symlink "$component"

  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      repo_ui_component_installing "$component"
    fi

    if ! clone_component_repository "$component"; then
      ui_error "$(format_template_message 'component_repo_failed' "$component")"
      return 1
    fi
  fi

  setup_component_symlinks "$component"

  setup_component "$component"

  _icon_msg_core "${GREEN}✓ " "$(format_template_message 'component_installed' "$component")"
  unset MEOW_COMPONENT_MANUAL_INSTALL
  return 0
}

# Collect all components and dependencies for multiple component update in topological order
collect_multiple_components_for_update() {
  local components_array=("$@")
  local -n result_ref="multiple_update_order"
  local all_components=()

  local collected_components=()
  for component in "${components_array[@]}"; do
    local component_and_deps=()
    collect_installed_dependencies_for_update "$component" component_and_deps

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

# Public wrapper for updating components - handles session management
update_component() {
  local components=("$@")

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_error "$(get_static_message 'no_components_specified_update')"
    return 1
  fi

  local multiple_update_order=()
  collect_multiple_components_for_update "${components[@]}"

  if [[ ${#multiple_update_order[@]} -eq 0 ]]; then
    ui_info "$(get_static_message 'no_components_to_update')"
    return 0
  fi

  ui_action_start "$(format_template_message "components_update_summary" "${#components[@]}" "$([ ${#components[@]} -gt 1 ] && echo "s" || echo "")")"
  ui_indent "$(format_template_message "components_update_total" "${#multiple_update_order[@]}")"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message 'update_order')"
    for comp in "${multiple_update_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        ui_verbose_info "  ➤ $comp (requested component)"
      else
        ui_verbose_info "  ↪ $comp (dependency)"
      fi
    done
  else
    local deps_list=""
    local requested_comp_list=""
    for comp in "${multiple_update_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        if [[ -z "$requested_comp_list" ]]; then
          requested_comp_list="$comp"
        else
          requested_comp_list="$requested_comp_list, $comp"
        fi
      else
        if [[ -z "$deps_list" ]]; then
          deps_list="$comp"
        else
          deps_list="$deps_list, $comp"
        fi
      fi
    done

    if [[ -n "$requested_comp_list" ]]; then
      ui_indent "$(format_template_message "components_update_requested" "$requested_comp_list")"
    fi
    if [[ -n "$deps_list" ]]; then
      ui_indent "$(format_template_message "components_update_dependencies" "$deps_list")"
    fi
  fi

  _initialize_session || {
    ui_error "$(get_static_message 'session_init_failed')"
    return 1
  }

  declare -ga MEOW_UPDATED_COMPONENTS=()

  local update_success=true
  for component in "${multiple_update_order[@]}"; do
    local comp_is_dependency=false

    local is_requested_component=false
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" == "$component" ]]; then
        is_requested_component=true
        break
      fi
    done

    if [[ "$is_requested_component" == "false" ]]; then
      comp_is_dependency=true
    fi

    if ! _update_single_component "$component" "$comp_is_dependency"; then
      ui_warning "$(format_template_message "component_update_failed_continue" "$component")"
    fi
  done

  _finalize_session
  unset MEOW_UPDATED_COMPONENTS

  return 0
}

# Internal recursive function for updating components
# Collect all installed dependencies for update in topological order
collect_installed_dependencies_for_update() {
  local component="$1"
  local -n result_ref="$2"
  local all_components=()

  collect_installed_dependencies_recursively "$component" all_components

  all_components+=("$component")

  local sorted_deps=()
  topological_sort_for_installation all_components sorted_deps
  result_ref=("${sorted_deps[@]}")
}

# Recursively collect all installed dependencies of a component for update
collect_installed_dependencies_recursively() {
  local component="$1"
  local -n all_deps_ref="$2"

  _collect_installed_deps_rec() {
    local comp="$1"
    local dependencies=()

    get_component_dependencies "$comp" dependencies

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]] && is_component_installed "$dep"; then
        local already_added=false
        for existing in "${all_deps_ref[@]}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_added=true
            break
          fi
        done

        if [[ "$already_added" == "false" ]]; then
          all_deps_ref+=("$dep")
          _collect_installed_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_installed_deps_rec "$component"
}

# Update a single component without dependencies (used by topologically sorted update)
_update_single_component() {
  local component="$1"
  local is_dependency="${2:-false}"

  local already_updated=false
  for updated_comp in "${MEOW_UPDATED_COMPONENTS[@]}"; do
    if [[ "$updated_comp" == "$component" ]]; then
      already_updated=true
      break
    fi
  done

  if [[ "$already_updated" == "true" ]]; then
    ui_verbose_info "$(format_template_message "component_already_updated" "$component")"
    return 0
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    ui_error "$(format_template_message 'component_not_found' "$component")"
    return 1
  fi

  if ! is_component_installed "$component"; then
    ui_verbose_info "$(format_template_message "component_not_installed_skip_update" "$component")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_component_updating "$component"
  else
    if [[ "$is_dependency" == "true" ]]; then
      ui_dependency "$(format_template_message "component_updating_prefix" "$component")"
    else
      ui_component_updating "$component"
    fi
  fi

  MEOW_UPDATED_COMPONENTS+=("$component")

  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      ui_step_header "$(format_template_message "component_updating_repository" "$component")"
    fi
    if update_component_repository "$component"; then
      ui_verbose_action_success "$(get_static_message 'repo_updated')"
    else
      ui_warning "$(get_static_message "component_repo_update_failed")"
    fi
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(format_template_message "component_updating_packages" "$component")"
  fi
  if update_component_packages "$component"; then
    ui_verbose_action_success "$(get_static_message 'packages_updated')"
  else
    ui_warning "$(get_static_message "component_packages_update_failed")"
  fi

  setup_component "$component"

  setup_component_symlinks "$component"

  _icon_msg_core "${CYAN}✓ " "$(format_template_message 'component_updated' "$component")"

  return 0
}

# Collect all components for multiple component uninstall in topological order
collect_multiple_components_for_uninstall() {
  local filter_source_components="false"
  local skip_preset_checks="false"
  local exclude_preset=""

  # Process optional flags
  while [[ ${#@} -gt 0 ]]; do
    case "${@: -1}" in
      "--filter-source")
        filter_source_components="true"
        set -- "${@:1:$(($#-1))}" # Remove last argument
        ;;
      "--skip-preset-checks")
        skip_preset_checks="true"
        set -- "${@:1:$(($#-1))}" # Remove last argument
        ;;
      --exclude-preset=*)
        exclude_preset="${@: -1}"
        exclude_preset="${exclude_preset#--exclude-preset=}"
        set -- "${@:1:$(($#-1))}" # Remove last argument
        ;;
      *)
        break
        ;;
    esac
  done

  local components_array=("$@")
  local -n result_ref="multiple_uninstall_order"
  local all_components=()

  local collected_components=()
  local dependencies_to_check=()

  # Add initial components, with optional filtering
  if [[ "$filter_source_components" == "true" ]]; then
    # Filter source components using the same logic as dependencies
    local source_components_to_filter=("${components_array[@]}")
    local filtered_source_components=()
    filter_removable_dependencies_with_context source_components_to_filter components_array filtered_source_components "$skip_preset_checks" "$exclude_preset"
    collected_components=("${filtered_source_components[@]}")
  else
    # Add source components without filtering (original behavior)
    for component in "${components_array[@]}"; do
      collected_components+=("$component")
    done
  fi

  for component in "${components_array[@]}"; do
    local dependencies=()
    get_component_dependencies "$component" dependencies

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]] && is_component_installed "$dep"; then
        local already_added=false
        for existing in "${dependencies_to_check[@]}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_added=true
            break
          fi
        done
        if [[ "$already_added" == "false" ]]; then
          dependencies_to_check+=("$dep")
        fi
      fi
    done
  done

  local previous_count=0
  local current_count=${#collected_components[@]}

  while [[ $current_count -gt $previous_count ]]; do
    previous_count=$current_count
    dependencies_to_check=()

    for component in "${collected_components[@]}"; do
      local dependencies=()
      get_component_dependencies "$component" dependencies

      for dep in "${dependencies[@]}"; do
        if [[ -n "$dep" ]] && is_component_installed "$dep"; then
          local already_added=false
          for existing in "${dependencies_to_check[@]}"; do
            if [[ "$existing" == "$dep" ]]; then
              already_added=true
              break
            fi
          done
          for existing in "${collected_components[@]}"; do
            if [[ "$existing" == "$dep" ]]; then
              already_added=true
              break
            fi
          done
          if [[ "$already_added" == "false" ]]; then
            dependencies_to_check+=("$dep")
          fi
        fi
      done
    done

    if [[ ${#dependencies_to_check[@]} -gt 0 ]]; then
      local all_components_to_remove=("${collected_components[@]}" "${dependencies_to_check[@]}")
      local removable_dependencies=()
      filter_removable_dependencies_with_context dependencies_to_check all_components_to_remove removable_dependencies "$skip_preset_checks" "$exclude_preset"

      for dep in "${removable_dependencies[@]}"; do
        local already_added=false
        for existing in "${collected_components[@]}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_added=true
            break
          fi
        done
        if [[ "$already_added" == "false" ]]; then
          collected_components+=("$dep")
        fi
      done
    fi

    current_count=${#collected_components[@]}
  done

  result_ref=("${collected_components[@]}")
}

# Public wrapper for uninstalling components - handles session management
uninstall_component() {
  local components=("$@")
  local force_flag=""
  local skip_preset_checks="false"
  local exclude_preset=""

  # Process flags
  while [[ ${#components[@]} -gt 0 ]]; do
    case "${components[-1]}" in
      "--force")
        force_flag="--force"
        unset 'components[-1]'
        ;;
      "--skip-preset-checks")
        skip_preset_checks="true"
        unset 'components[-1]'
        ;;
      --exclude-preset=*)
        exclude_preset="${components[-1]}"
        exclude_preset="${exclude_preset#--exclude-preset=}"
        unset 'components[-1]'
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_error "$(get_static_message 'no_components_specified_uninstall')"
    return 1
  fi

  for component in "${components[@]}"; do
    if ! is_component_installed "$component"; then
      ui_warning "$(format_template_message "component_not_installed_warning" "$component")"
      return 1
    fi

    local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
    if [[ ! -f "$component_file" ]]; then
      ui_error "$(format_template_message "component_file_not_found_error" "$component_file")"
      return 1
    fi
  done

  if [[ "$force_flag" != "--force" ]]; then
    for component in "${components[@]}"; do
      local dependent_components
      mapfile -t dependent_components < <(get_components_depending_on "$component")

      local filtered_dependents=()
      for dep in "${dependent_components[@]}"; do
        if [[ -n "$dep" ]]; then
          local dep_is_being_uninstalled=false
          for uninstall_comp in "${components[@]}"; do
            if [[ "$uninstall_comp" == "$dep" ]]; then
              dep_is_being_uninstalled=true
              break
            fi
          done
          if [[ "$dep_is_being_uninstalled" == "false" ]]; then
            filtered_dependents+=("$dep")
          fi
        fi
      done

      if [[ ${#filtered_dependents[@]} -gt 0 ]]; then
        ui_error "$(format_template_message "component_uninstall_blocked_components" "$component")"
        for dep_comp in "${filtered_dependents[@]}"; do
          ui_action_error "$(format_template_message "component_uninstall_dependent_item" "$dep_comp")"
        done
        ui_error "$(get_static_message "component_uninstall_use_force")"
        return 1
      fi

      local dependent_presets
      mapfile -t dependent_presets < <(get_presets_depending_on "$component" "$exclude_preset")

      local filtered_presets=()
      for current_preset in "${dependent_presets[@]}"; do
        if [[ -n "$current_preset" ]]; then
          filtered_presets+=("$current_preset")
        fi
      done

      # Skip preset dependency check if flag is set
      if [[ ${#filtered_presets[@]} -gt 0 && "$skip_preset_checks" == "false" ]]; then
        ui_error "$(format_template_message "component_uninstall_blocked_presets" "$component")"
        for current_preset in "${filtered_presets[@]}"; do
          ui_action_error "$(format_template_message "component_uninstall_dependent_item" "$current_preset")"
        done
        ui_error "$(get_static_message "component_uninstall_presets_use_force")"
        return 1
      fi
    done
  else
    ui_info "$(get_static_message "component_force_flag_detected")"
  fi

  local multiple_uninstall_order=()
  local collect_args=("${components[@]}")
  if [[ "$skip_preset_checks" == "true" ]]; then
    collect_args+=("--skip-preset-checks")
  fi
  if [[ -n "$exclude_preset" ]]; then
    collect_args+=("--exclude-preset=$exclude_preset")
  fi
  collect_multiple_components_for_uninstall "${collect_args[@]}"

  if [[ ${#multiple_uninstall_order[@]} -eq 0 ]]; then
    ui_info "$(get_static_message "no_components_to_uninstall")"
    return 0
  fi

  local component_count=${#components[@]}
  local plural_suffix=""
  if [[ $component_count -gt 1 ]]; then
    plural_suffix="s"
  fi
  ui_action_start "$(format_template_message "components_uninstall_summary" "$component_count" "$plural_suffix")"
  ui_indent "$(format_template_message "components_uninstall_total" "${#multiple_uninstall_order[@]}")"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "component_uninstall_order")"
    for comp in "${multiple_uninstall_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        ui_verbose_info "$(format_template_message "component_requested_uninstall_indicator" "$comp")"
      else
        ui_verbose_info "$(format_template_message "component_unused_dependency_indicator" "$comp")"
      fi
    done
  else
    local deps_list=""
    local requested_comp_list=""
    for comp in "${multiple_uninstall_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        if [[ -z "$requested_comp_list" ]]; then
          requested_comp_list="$comp"
        else
          requested_comp_list="$requested_comp_list, $comp"
        fi
      else
        if [[ -z "$deps_list" ]]; then
          deps_list="$comp"
        else
          deps_list="$deps_list, $comp"
        fi
      fi
    done

    if [[ -n "$requested_comp_list" ]]; then
      ui_indent "$(format_template_message "components_uninstall_requested" "$requested_comp_list")"
    fi
    if [[ -n "$deps_list" ]]; then
      ui_indent "$(format_template_message "components_uninstall_unused" "$deps_list")"
    fi
  fi

  if ! _initialize_session; then
    ui_error "$(get_static_message 'session_init_failed')"
    return 1
  fi

  local overall_success=true

  for component in "${multiple_uninstall_order[@]}"; do
    local is_requested_component=false
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" == "$component" ]]; then
        is_requested_component=true
        break
      fi
    done

    if ! _uninstall_single_component "$component" "$is_requested_component"; then
      ui_warning "$(format_template_message "component_uninstall_failed" "$component")"
      overall_success=false
    fi
  done

  _finalize_session

  if [[ "$overall_success" == "true" ]]; then
    return 0
  else
    ui_warning "$(format_template_message "components_uninstalled_with_errors" "$([ ${#components[@]} -gt 1 ] && echo "s" || echo "")")"
    return 1
  fi
}

# Uninstall a single component - internal function called during batch uninstall
_uninstall_single_component() {
  local component="$1"
  local is_requested_component="${2:-true}"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_component_uninstalling "$component"
  else
    if [[ "$is_requested_component" == "true" ]]; then
      ui_component_uninstalling "$component"
    else
      ui_dependency "$(format_template_message "component_removing_unused" "$component")"
    fi
  fi

  local success=true

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "component_removing_symlinks")"
  fi
  if remove_component_symlinks "$component"; then
    ui_verbose_action_success "$(get_static_message "component_symlinks_removed_successfully")"
  else
    ui_warning "$(get_static_message "component_symlinks_removal_failed")"
    success=false
  fi

  cleanup_component "$component"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "component_uninstalling_packages")"
  fi
  if uninstall_component_packages "$component"; then
    ui_verbose_action_success "$(get_static_message 'packages_uninstalled')"
  else
    ui_warning "$(get_static_message "component_packages_uninstall_failed")"
    success=false
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$(get_static_message "component_removing_tracking")"
  fi
  remove_component_symlink "$component"
  ui_verbose_action_success "$(get_static_message "component_tracking_removed")"

  if [[ "$success" == "true" ]]; then
    _icon_msg_core "${RED}✓ " "$(format_template_message 'component_uninstalled' "$component")"
    return 0
  else
    return 1
  fi
}
