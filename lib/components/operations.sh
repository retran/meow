#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_OPERATIONS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_OPERATIONS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/session.sh"

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

  # For each requested component, collect all its dependencies recursively
  local collected_components=()
  for component in "${components_array[@]}"; do
    # Use existing function to collect dependencies
    local component_and_deps=()
    collect_all_dependencies_for_installation "$component" component_and_deps

    # Add all components to our list (avoiding duplicates)
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

  # Now do final topological sort on all collected components
  local sorted_components=()
  topological_sort_for_installation collected_components sorted_components
  result_ref=("${sorted_components[@]}")
}

# Public wrapper for installing components - handles session management
install_component() {
  local components=()
  local is_manual="true"

  # Parse arguments
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

  # Ensure at least one component is specified
  if [[ ${#components[@]} -eq 0 ]]; then
    error "No components specified for installation"
    return 1
  fi

  # Get all components in topological order
  local multiple_installation_order=()
  collect_multiple_components_for_installation "${components[@]}"

  if [[ ${#multiple_installation_order[@]} -eq 0 ]]; then
    info "No components to install"
    return 0
  fi

  # Show summary of what will be installed
  # Filter out already installed components for the summary
  local components_to_install=()
  for comp in "${multiple_installation_order[@]}"; do
    if ! is_component_installed "$comp"; then
      components_to_install+=("$comp")
    fi
  done

  # Show what will be installed
  action_msg "Will install ${#components[@]} component$([ ${#components[@]} -gt 1 ] && echo "s") with dependencies"
  if [[ ${#components_to_install[@]} -gt 0 ]]; then
    indent_msg "Total components to install: ${#components_to_install[@]}"

    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      step_header "Installation order:"
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
          verbose_info "  ➤ $comp (requested component)$status"
        else
          verbose_info "  ↪ $comp (dependency)$status"
        fi
      done
    else
      # Show compact summary
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
        indent_msg "Requested components: $requested_comp_list"
      fi
      if [[ -n "$deps_list" ]]; then
        indent_msg "New dependencies: $deps_list"
      fi
    fi
  else
    indent_msg "All components already installed"
  fi

  # Initialize session and tracking array
  _initialize_session || {
    error "Session initialization failed"
    return 1
  }

  declare -ga MEOW_INSTALLING_COMPONENTS=()

  # Install all components in topological order
  local install_success=true
  for component in "${multiple_installation_order[@]}"; do
    # Determine if this is a requested component (manual) or dependency (auto)
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
      comp_is_manual="false" # Dependencies are always automatic
    fi

    if ! _install_single_component "$component" "$comp_is_manual" "$comp_is_dependency"; then
      error "Failed to install component: $component"
      install_success=false
      break
    fi
  done

  # Cleanup
  _finalize_session
  unset MEOW_INSTALLING_COMPONENTS

  if [[ "$install_success" != "true" ]]; then
    return 1
  fi

  return 0
}

# Install a single component without dependencies (used by topologically sorted install)
# Args: $1 - component name, $2 - is_manual flag, $3 - is_dependency flag
_install_single_component() {
  local component="$1"
  local is_manual="${2:-true}"
  local is_dependency="${3:-false}"

  # Check if component is already being installed in this session
  local already_installing=false
  for installing_comp in "${MEOW_INSTALLING_COMPONENTS[@]}"; do
    if [[ "$installing_comp" == "$component" ]]; then
      already_installing=true
      break
    fi
  done

  if [[ "$already_installing" == "true" ]]; then
    verbose_info "Component '$component' already being installed in this session, skipping"
    return 0
  fi

  # Check if component exists
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    error "Component '$component' not found"
    return 1
  fi

  # Check if component is available on this platform
  if ! is_component_available "$component"; then
    error "Component '$component' is not available on this platform or dependencies are missing"
    return 1
  fi

  # Check if already installed
  if is_component_installed "$component"; then
    # If manually installing and not already manually tracked, add to manual tracking
    if [[ "$is_manual" == "true" ]] && ! is_component_manually_installed "$component"; then
      mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
      ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}"
      success_tick_msg "Component '$component' marked as manually installed"
    else
      verbose_info "Component '$component' is already installed"
    fi
    return 0
  fi

  # Show component header
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    header "Installing component: $component"
  else
    if [[ "$is_dependency" == "true" ]]; then
      dependency_msg "Installing component: $component"
    else
      action_msg "Installing component: $component"
    fi
  fi

  # Mark this component as being installed
  MEOW_INSTALLING_COMPONENTS+=("$component")

  # Install packages for this component
  export MEOW_COMPONENT_MANUAL_INSTALL="$is_manual"
  if ! install_component_packages "$component"; then
    error "Failed to install packages for component '$component'"
    return 1
  fi

  # Mark component as installed FIRST (create symlink in .installed/components/)
  # This must be done before setting up config symlinks since they reference .installed paths
  install_component_symlink "$component"

  # Handle repository-based components
  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      step_header "Installing repository-based component: $component"
    fi

    # Clone repository
    if ! clone_component_repository "$component"; then
      error "Failed to clone repository for component '$component'"
      return 1
    fi
  fi

  # Setup symlinks (after component is available in .installed)
  setup_component_symlinks "$component"

  # Run component initialization if available (after component is marked as installed)
  setup_component "$component"

  success_tick_msg "Component '$component' installed successfully"
  unset MEOW_COMPONENT_MANUAL_INSTALL
  return 0
}

# Collect all components and dependencies for multiple component update in topological order
collect_multiple_components_for_update() {
  local components_array=("$@")
  local -n result_ref="multiple_update_order"
  local all_components=()

  # For each requested component, collect all its installed dependencies recursively
  local collected_components=()
  for component in "${components_array[@]}"; do
    # Use existing function to collect installed dependencies
    local component_and_deps=()
    collect_installed_dependencies_for_update "$component" component_and_deps

    # Add all components to our list (avoiding duplicates)
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

  # Now do final topological sort on all collected components
  local sorted_components=()
  topological_sort_for_installation collected_components sorted_components
  result_ref=("${sorted_components[@]}")
}

# Public wrapper for updating components - handles session management
update_component() {
  local components=("$@")

  # Ensure at least one component is specified
  if [[ ${#components[@]} -eq 0 ]]; then
    error "No components specified for update"
    return 1
  fi

  # Get all components in topological order
  local multiple_update_order=()
  collect_multiple_components_for_update "${components[@]}"

  if [[ ${#multiple_update_order[@]} -eq 0 ]]; then
    info "No components to update"
    return 0
  fi

  # Show summary of what will be updated
  action_msg "Will update ${#components[@]} component$([ ${#components[@]} -gt 1 ] && echo "s") with dependencies"
  indent_msg "Total components to update: ${#multiple_update_order[@]}"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Update order:"
    for comp in "${multiple_update_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        verbose_info "  ➤ $comp (requested component)"
      else
        verbose_info "  ↪ $comp (dependency)"
      fi
    done
  else
    # Show compact summary
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
      indent_msg "Requested components: $requested_comp_list"
    fi
    if [[ -n "$deps_list" ]]; then
      indent_msg "Dependencies: $deps_list"
    fi
  fi

  # Initialize session and tracking array
  _initialize_session || {
    error "Session initialization failed"
    return 1
  }

  declare -ga MEOW_UPDATED_COMPONENTS=()

  # Update all components in topological order
  local update_success=true
  for component in "${multiple_update_order[@]}"; do
    # Determine if this is a requested component or dependency
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
      warning "Failed to update component: $component, continuing with other components"
      # Continue with other components rather than failing completely
    fi
  done

  # Cleanup
  _finalize_session
  unset MEOW_UPDATED_COMPONENTS

  return 0
}

# Internal recursive function for updating components
# Collect all installed dependencies for update in topological order
# Args: $1 - component name, $2 - array name to store dependencies (including the component itself)
collect_installed_dependencies_for_update() {
  local component="$1"
  local -n result_ref="$2"
  local all_components=()

  # First, collect all installed dependencies recursively
  collect_installed_dependencies_recursively "$component" all_components

  # Add the main component itself at the end
  all_components+=("$component")

  # Then sort them topologically (dependencies first, then dependents)
  local sorted_deps=()
  topological_sort_for_installation all_components sorted_deps
  result_ref=("${sorted_deps[@]}")
}

# Recursively collect all installed dependencies of a component for update
# Args: $1 - component name, $2 - array name to store all dependencies
collect_installed_dependencies_recursively() {
  local component="$1"
  local -n all_deps_ref="$2"

  _collect_installed_deps_rec() {
    local comp="$1"
    local dependencies=()

    get_component_dependencies "$comp" dependencies

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]] && is_component_installed "$dep"; then
        # Check if already collected
        local already_added=false
        for existing in "${all_deps_ref[@]}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_added=true
            break
          fi
        done

        if [[ "$already_added" == "false" ]]; then
          all_deps_ref+=("$dep")
          # Recursively collect dependencies of this dependency
          _collect_installed_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_installed_deps_rec "$component"
}

# Update a single component without dependencies (used by topologically sorted update)
# Args: $1 - component name, $2 - is_dependency flag
_update_single_component() {
  local component="$1"
  local is_dependency="${2:-false}"

  # Check if component has already been updated in this session
  local already_updated=false
  for updated_comp in "${MEOW_UPDATED_COMPONENTS[@]}"; do
    if [[ "$updated_comp" == "$component" ]]; then
      already_updated=true
      break
    fi
  done

  if [[ "$already_updated" == "true" ]]; then
    verbose_info "Component '$component' already updated in this session, skipping"
    return 0
  fi

  # Check if component exists
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    error "Component '$component' not found"
    return 1
  fi

  # Check if component is installed
  if ! is_component_installed "$component"; then
    verbose_info "Component '$component' is not installed, skipping update"
    return 0
  fi

  # Show component header
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    header "Updating component: $component"
  else
    if [[ "$is_dependency" == "true" ]]; then
      dependency_msg "Updating component: $component"
    else
      action_msg "Updating component: $component"
    fi
  fi

  # Mark this component as being updated
  MEOW_UPDATED_COMPONENTS+=("$component")

  # Update repository if it's a repository-based component
  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      step_header "Updating repository for $component"
    fi
    if update_component_repository "$component"; then
      verbose_success_tick_msg "Repository updated successfully"
    else
      warning "Repository update failed, continuing with package updates"
    fi
  fi

  # Update packages for the component
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Updating packages for $component"
  fi
  if update_component_packages "$component"; then
    verbose_success_tick_msg "Packages updated successfully"
  else
    warning "Some package updates may have failed"
  fi

  # Re-run initialization
  setup_component "$component"

  # Update symlinks
  setup_component_symlinks "$component"

  success_tick_msg "Component '$component' updated successfully"
  return 0
}

# Collect all components for multiple component uninstall in topological order
collect_multiple_components_for_uninstall() {
  local components_array=("$@")
  local -n result_ref="multiple_uninstall_order"
  local all_components=()

  # For each requested component, collect dependencies that can be safely removed
  local collected_components=()
  local dependencies_to_check=()

  # First, add all requested components (they will be removed regardless)
  for component in "${components_array[@]}"; do
    collected_components+=("$component")
  done

  # Then collect dependencies of requested components
  for component in "${components_array[@]}"; do
    local dependencies=()
    get_component_dependencies "$component" dependencies

    # Add dependencies to check list (not directly to removal list)
    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]] && is_component_installed "$dep"; then
        # Check if already added to dependencies check list
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

  # Iteratively collect removable dependencies
  local previous_count=0
  local current_count=${#collected_components[@]}

  while [[ $current_count -gt $previous_count ]]; do
    previous_count=$current_count
    dependencies_to_check=()

    # Collect dependencies of all currently collected components
    for component in "${collected_components[@]}"; do
      local dependencies=()
      get_component_dependencies "$component" dependencies

      # Add dependencies to check list (not directly to removal list)
      for dep in "${dependencies[@]}"; do
        if [[ -n "$dep" ]] && is_component_installed "$dep"; then
          # Check if already added to dependencies check list
          local already_added=false
          for existing in "${dependencies_to_check[@]}"; do
            if [[ "$existing" == "$dep" ]]; then
              already_added=true
              break
            fi
          done
          # Also check if already in collected components
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

    # Filter dependencies to keep only removable ones
    if [[ ${#dependencies_to_check[@]} -gt 0 ]]; then
      # Include all currently collected components in the check context
      local all_components_to_remove=("${collected_components[@]}" "${dependencies_to_check[@]}")
      local removable_dependencies=()
      filter_removable_dependencies_with_context dependencies_to_check all_components_to_remove removable_dependencies

      # Add removable dependencies to collected components
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

  # Return collected components (they're already in good order)
  result_ref=("${collected_components[@]}")
}

# Public wrapper for uninstalling components - handles session management
uninstall_component() {
  local components=("$@")
  local force_flag=""

  # Check for --force flag in the last argument
  if [[ ${#components[@]} -gt 0 && "${components[-1]}" == "--force" ]]; then
    force_flag="--force"
    # Remove --force from components array
    unset 'components[-1]'
  fi

  # Ensure at least one component is specified
  if [[ ${#components[@]} -eq 0 ]]; then
    error "No components specified for uninstall"
    return 1
  fi

  # Validate all components are installed
  for component in "${components[@]}"; do
    if ! is_component_installed "$component"; then
      warning "Component '$component' is not installed"
      return 1
    fi

    # Check if component exists
    local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
    if [[ ! -f "$component_file" ]]; then
      error "Component file not found: $component_file"
      return 1
    fi
  done

  # Check dependencies unless --force is used
  if [[ "$force_flag" != "--force" ]]; then
    for component in "${components[@]}"; do
      # Check if component is used by other components
      local dependent_components
      mapfile -t dependent_components < <(get_components_depending_on "$component")

      # Filter out empty elements and components that are also being uninstalled
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
        error "Cannot uninstall component '$component' because it is required by the following components:"
        for dep_comp in "${filtered_dependents[@]}"; do
          error_msg "  - $dep_comp"
        done
        error "Please uninstall the dependent components first, or use --force to override."
        return 1
      fi

      # Check if component is used by installed presets
      local dependent_presets
      mapfile -t dependent_presets < <(get_presets_depending_on "$component")

      # Filter out empty elements
      local filtered_presets=()
      for preset in "${dependent_presets[@]}"; do
        if [[ -n "$preset" ]]; then
          filtered_presets+=("$preset")
        fi
      done

      if [[ ${#filtered_presets[@]} -gt 0 ]]; then
        error "Cannot uninstall component '$component' because it is required by the following installed presets:"
        for preset in "${filtered_presets[@]}"; do
          error_msg "  - $preset"
        done
        error "Please uninstall the presets first, use a different preset configuration, or use --force to override."
        return 1
      fi
    done
  else
    info "Force flag detected - skipping dependency checks"
  fi

  # Get all components in uninstall order
  local multiple_uninstall_order=()
  collect_multiple_components_for_uninstall "${components[@]}"

  if [[ ${#multiple_uninstall_order[@]} -eq 0 ]]; then
    info "No components to uninstall"
    return 0
  fi

  # Show summary of what will be uninstalled
  action_msg "Will uninstall ${#components[@]} component$([ ${#components[@]} -gt 1 ] && echo "s") with dependencies"
  indent_msg "Total components to uninstall: ${#multiple_uninstall_order[@]}"

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Uninstall order:"
    for comp in "${multiple_uninstall_order[@]}"; do
      local is_requested_component=false
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" == "$comp" ]]; then
          is_requested_component=true
          break
        fi
      done

      if [[ "$is_requested_component" == "true" ]]; then
        verbose_info "  ➤ $comp (requested component)"
      else
        verbose_info "  ↪ $comp (unused dependency)"
      fi
    done
  else
    # Show compact summary
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
      indent_msg "Requested components: $requested_comp_list"
    fi
    if [[ -n "$deps_list" ]]; then
      indent_msg "Unused dependencies: $deps_list"
    fi
  fi

  # Initialize session
  if ! _initialize_session; then
    error "Session initialization failed"
    return 1
  fi

  local overall_success=true

  # Uninstall all components in order
  for component in "${multiple_uninstall_order[@]}"; do
    # Determine if this is a requested component or dependency
    local is_requested_component=false
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" == "$component" ]]; then
        is_requested_component=true
        break
      fi
    done

    if ! _uninstall_single_component "$component" "$is_requested_component"; then
      warning "Failed to uninstall component: $component"
      overall_success=false
      # Continue with other components rather than failing completely
    fi
  done

  # Finalize session
  _finalize_session

  if [[ "$overall_success" == "true" ]]; then
    return 0
  else
    warning "Component$([ ${#components[@]} -gt 1 ] && echo "s") uninstalled with some warnings/errors"
    return 1
  fi
}

# Uninstall a single component - internal function called during batch uninstall
_uninstall_single_component() {
  local component="$1"
  local is_requested_component="${2:-true}"

  # Show component header
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    title "Uninstalling component: $component"
  else
    if [[ "$is_requested_component" == "true" ]]; then
      action_msg "Uninstalling component: $component"
    else
      dependency_msg "Removing unused dependency: $component"
    fi
  fi

  local success=true

  # Step 1: Remove symlinks and restore backups
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Removing symlinks and restoring backups"
  fi
  if remove_component_symlinks "$component"; then
    verbose_success_tick_msg "Symlinks removed and backups restored successfully"
  else
    warning "Some symlink removal/backup restoration may have failed"
    success=false
  fi

  # Step 1.5: Run cleanup script
  cleanup_component "$component"

  # Step 2: Uninstall packages
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Uninstalling packages"
  fi
  if uninstall_component_packages "$component"; then
    verbose_success_tick_msg "Packages uninstalled successfully"
  else
    warning "Some package uninstallation may have failed"
    success=false
  fi

  # Step 3: Remove component tracking symlinks
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Removing component tracking"
  fi
  remove_component_symlink "$component"
  verbose_success_tick_msg "Component tracking removed"

  if [[ "$success" == "true" ]]; then
    success_tick_msg "Component '$component' uninstalled successfully"
    return 0
  else
    return 1
  fi
}
