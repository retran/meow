#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_CORE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_CORE_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/colors.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/tools.sh"
source "${MEOW}/lib/core/yaml.sh"

# Check if a component is currently installed
# Args: $1 - component name
# Returns: 0 if installed, 1 if not installed
is_component_installed() {
  local component="$1"
  [[ -L "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}" ]]
}

# Check if a component was manually installed (vs. auto-installed as dependency)
# Args: $1 - component name
# Returns: 0 if manually installed, 1 if not manually installed
is_component_manually_installed() {
  local component="$1"
  [[ -L "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" ]]
}

# Create symlink to mark component as installed
# Args: $1 - component name
# Side effects: Creates symlinks in installation tracking directories
install_component_symlink() {
  local component="$1"
  local component_path="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  if [[ ! -f "$component_path" ]]; then
    echo "$(format_template_message "component_file_not_found" "$component_path")" >&2
    return 1
  fi

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "$(format_template_message "dry_run_create_component_symlink" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}" "${MEOW_COMPONENTS_DIR}/${component}")"
    if [[ "${MEOW_COMPONENT_MANUAL_INSTALL:-}" == "true" ]]; then
      dry_run_ui_info "$(format_template_message "dry_run_mark_manual_install" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" "${MEOW_COMPONENTS_DIR}/${component}")"
    fi
    return 0
  fi

  # Create main installation tracking symlink
  mkdir -p "$MEOW_INSTALLED_COMPONENTS_DIR"
  ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}"

  # Mark as manually installed if flag is set
  if [[ "${MEOW_COMPONENT_MANUAL_INSTALL:-}" == "true" ]]; then
    mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
    ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}"
  fi
}

# Remove symlinks to mark component as uninstalled
# Args: $1 - component name
# Side effects: Removes symlinks from installation tracking directories
remove_component_symlink() {
  local component="$1"

  # Handle dry-run mode
  if is_dry_run; then
    dry_run_ui_info "$(format_template_message "dry_run_remove_component_symlink" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}")"
    dry_run_ui_info "$(format_template_message "dry_run_remove_manual_symlink" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}")"
    return 0
  fi

  # Remove from installed components
  rm -rf "${MEOW_INSTALLED_COMPONENTS_DIR:?}/${component}"

  # Remove from manually installed components
  rm -rf "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR:?}/${component}"
}

# Check if a component is available on the current platform and has satisfied dependencies
is_component_available() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1

  # Check platform compatibility
  if yaml_path_exists "$component_file" ".platforms"; then
    local current_platform
    current_platform=$(get_platform)
    local platforms=""
    platforms=$(read_yaml_array "$component_file" ".platforms[]" 2>/dev/null | tr '\n' ' ')

    if [[ -n "$platforms" ]]; then
      local platform_supported=false
      for platform in $platforms; do
        platform=$(echo "$platform" | tr -d '"')
        if [[ "$platform" == "$current_platform" ]]; then
          platform_supported=true
          break
        fi
      done

      if [[ "$platform_supported" == "false" ]]; then
        return 1
      fi
    fi
  fi

  # Check dependencies are available
  local dependencies=""
  if yaml_path_exists "$component_file" ".depends_on"; then
    dependencies=$(read_yaml_array "$component_file" ".depends_on[]" 2>/dev/null | tr '\n' ' ')
    for dep in $dependencies; do
      dep=$(echo "$dep" | tr -d '"')
      if [[ -n "$dep" ]] && ! is_component_available "$dep"; then
        return 1
      fi
    done
  fi

  return 0
}

# List all available components with their installation status
list_components() {
  local show_installed_only="${1:-false}"
  local show_verbose="${2:-true}" # Default to showing statuses

  # Check if component directory exists
  if [[ ! -d "$MEOW_COMPONENTS_DIR" ]]; then
    ui_error "$(format_template_message "components_directory_not_found" "$MEOW_COMPONENTS_DIR")"
    return 1
  fi

  local components=()
  mapfile -t components < <(find "$MEOW_COMPONENTS_DIR" -maxdepth 1 -type d -exec basename {} \; | sort)

  for component in "${components[@]}"; do
    # Skip the base components directory itself
    [[ "$component" == "components" ]] && continue

    local installed="false"
    local status="available"
    local status_color="${BLUE}"
    local status_symbol="○"

    if is_component_installed "$component"; then
      installed="true"
      status="installed"
      status_color="${GREEN}"
      status_symbol="✓"
    fi

    # Skip non-installed components if showing installed only
    if [[ "$show_installed_only" == "true" && "$installed" == "false" ]]; then
      continue
    fi

    # Check if component is available on current platform
    if ! is_component_available "$component"; then
      status="incompatible"
      status_color="${RED}"
      status_symbol="✗"
    fi

    if [[ "$show_verbose" == "true" ]]; then
      local manually_installed=""
      if [[ "$installed" == "true" ]] && is_component_manually_installed "$component"; then
        status="installed (manual)"
      fi

      # Format as table with colored status
      printf "${status_color}%-2s${RESET} %-30s ${status_color}%s${RESET}\n" "$status_symbol" "$component" "$status"
    else
      echo "$component"
    fi
  done
}

# Execute component setup script
setup_component() {
  local component="$1"
  local component_dir="${MEOW_INSTALLED_COMPONENTS_DIR}/${component}"
  local init_script="${component_dir}/scripts/setup.sh"

  if [[ -f "$init_script" ]]; then
    _icon_msg_core "${BLUE}➤ " "$(format_template_message 'setting_up_component' "$component")"

    # Handle dry-run mode
    if dry_run_script_execution "$init_script" "setup script for $component"; then
      return 0
    fi

    [[ ! -x "$init_script" ]] && chmod +x "$init_script"
    if "$init_script" "$component" "$MEOW"; then
      ui_action_success "$(get_static_message 'component_setup_completed')"
    else
      ui_error "$(get_static_message 'component_setup_failed')"
      return 1
    fi
  fi
}

# Execute component cleanup script
cleanup_component() {
  local component="$1"
  local component_dir="${MEOW_INSTALLED_COMPONENTS_DIR}/${component}"
  local cleanup_script="${component_dir}/scripts/cleanup.sh"

  if [[ -f "$cleanup_script" ]]; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      _icon_msg_core "${YELLOW}➤ " "$(format_template_message 'cleaning_component' "$component")"
    fi

    # Handle dry-run mode
    if dry_run_script_execution "$cleanup_script" "cleanup script for $component"; then
      return 0
    fi

    [[ ! -x "$cleanup_script" ]] && chmod +x "$cleanup_script"
    if "$cleanup_script" "$component" "$MEOW"; then
      ui_verbose_action_success "$(get_static_message 'component_cleanup_completed')"
    else
      ui_warning "$(get_static_message 'component_cleanup_failed')"
      return 1
    fi
  fi
}
