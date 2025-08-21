#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_COMPONENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_COMPONENTS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/tools.sh"
source "${MEOW}/lib/core/yaml.sh"

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/mas.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/pacman.sh"
source "${MEOW}/lib/package/pipx.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/vscode.sh"

source "${MEOW}/lib/symlinks/symlinks.sh"

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
    echo "Component file not found: $component_path" >&2
    return 1
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

  # Remove from installed components
  rm -rf "${MEOW_INSTALLED_COMPONENTS_DIR:?}/${component}"

  # Remove from manually installed components
  rm -rf "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR:?}/${component}"
}

# Install all packages defined for a component across applicable package managers
# Args:
#   $1 - component name
install_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    error "Component directory not found: $component_dir"
    return 1
  fi

  # Проверяем, есть ли папка packages
  if [[ ! -d "$packages_dir" ]]; then
    # Если нет папки packages, значит компонент не требует установки пакетов
    return 0
  fi

  # Show packages section header only in verbose mode
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Installing packages for $component"
  fi

  local has_packages=false
  local package_errors=0

  # Install packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    if [[ -f "${packages_dir}/homebrew.list" ]]; then
      if _install_packages_for_component_manager "$component" "homebrew"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
    if [[ -f "${packages_dir}/mas.list" ]]; then
      if _install_packages_for_component_manager "$component" "mas"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    if [[ -f "${packages_dir}/apt.list" ]]; then
      if _install_packages_for_component_manager "$component" "apt"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_ALPINE" == "true" ]]; then
    if [[ -f "${packages_dir}/apk.list" ]]; then
      if _install_packages_for_component_manager "$component" "apk"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_ARCH" == "true" ]]; then
    if [[ -f "${packages_dir}/pacman.list" ]]; then
      if _install_packages_for_component_manager "$component" "pacman"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  fi

  # Install packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    if [[ -f "${packages_dir}/${mgr}.list" ]]; then
      if _install_packages_for_component_manager "$component" "$mgr"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  done

  # Show compact summary if we had packages and we're not in verbose mode
  if [[ "$has_packages" == "true" && "$MEOW_VERBOSE" != "true" ]]; then
    if [[ $package_errors -gt 0 ]]; then
      indent_msg "Packages: ✗ $package_errors errors occurred"
    fi
  fi

  return $([[ $package_errors -eq 0 ]] && echo 0 || echo 1)
}

# Uninstall all packages defined for a component across applicable package managers
# Args:
#   $1 - component name
uninstall_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    error "Component directory not found: $component_dir"
    return 1
  fi

  # Проверяем, есть ли папка packages
  if [[ ! -d "$packages_dir" ]]; then
    # Если нет папки packages, значит компонент не требует удаления пакетов
    return 0
  fi

  # Uninstall packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "homebrew"
    _uninstall_packages_for_component_manager "$component" "mas"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apt"
  elif [[ "$IS_ALPINE" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apk"
  elif [[ "$IS_ARCH" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "pacman"
  fi

  # Uninstall packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    _uninstall_packages_for_component_manager "$component" "$mgr"
  done

  return 0
}

# Helper: uninstall packages for a specific package manager
# Args:
#   $1 - component name
#   $2 - package manager name
_uninstall_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="uninstall_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  # Skip if package manager uninstall function doesn't exist
  declare -F "$fn" >/dev/null || return

  # Skip if package file doesn't exist
  [[ -f "$packages_file" ]] || return

  # Call the uninstall function with component name
  "$fn" "$component"
}

# Helper: install packages for a specific package manager
# Args:
#   $1 - component name
#   $2 - package manager name
_install_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="install_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  # Skip if package manager install function doesn't exist
  declare -F "$fn" >/dev/null || return 0

  # Skip if package file doesn't exist
  [[ -f "$packages_file" ]] || return 0

  # Call the install function with component name and return its exit code
  "$fn" "$component"
  return $?
}

# Helper: Get normalized path to component file
# Args: $1 - component name (may include "components/" prefix)
# Returns: Absolute path to component.yaml file
_get_component_file_path() {
  local component="$1"
  if [[ "$component" == components/* ]]; then
    local component_name="${component#components/}"
    echo "${MEOW_COMPONENTS_DIR}/${component_name}/component.yaml"
  else
    echo "${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  fi
}

# Update packages for a specific package manager within a component
# Args:
#   $1 - package manager name (e.g., "homebrew", "apt", "npm")
#   $2 - CLI command name for the package manager
#   $3 - component name
_update_package_manager() {
  local manager_name="$1"
  local cli_command="$2"
  local component="$3"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"

  # Skip if package manager CLI is not available
  if ! command -v "$cli_command" >/dev/null 2>&1; then
    return 0
  fi

  # Skip if package file doesn't exist
  if [[ ! -f "$packages_file" ]]; then
    return 0
  fi

  # Check if update function exists for this package manager
  local update_function_name="update_${manager_name}_packages"
  if ! declare -F "$update_function_name" >/dev/null; then
    error_msg "Update function ${update_function_name} not found."
    return 1
  fi

  # Call the update function with component name
  "$update_function_name" "$component"
}

# Update all packages for a component across all applicable package managers
# Args:
#   $1 - component name
update_component_packages() {
  local component="$1"
  local had_updates=false
  local had_error=false

  # Update packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    _update_package_manager "homebrew" "brew" "$component"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true

    _update_package_manager "mas" "mas" "$component"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _update_package_manager "apt" "apt-get" "$component"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  if [[ "$IS_ALPINE" == "true" ]]; then
    _update_package_manager "apk" "apk" "$component"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  # Update packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    _update_package_manager "$mgr" "$mgr" "$component"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  done

  # Return appropriate status code
  if $had_error; then
    return 1
  elif $had_updates; then
    return 0
  else
    return 0
  fi
}

# Check if a component is available on the current platform and has satisfied dependencies
# Args: $1 - component name
# Returns: 0 if available, 1 if not available
is_component_available() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1

  # Check platform compatibility if platforms are specified
  if yaml_path_exists "$component_file" ".platforms"; then
    local current_platform=""
    if [[ "$IS_MACOS" == "true" ]]; then
      current_platform="macos"
    elif [[ "$IS_DEBIAN_BASED" == "true" || "$IS_ALPINE" == "true" || "$IS_ARCH" == "true" ]]; then
      current_platform="linux"
    fi

    if [[ -n "$current_platform" ]]; then
      local platform_supported=false
      local platforms
      platforms=$(read_yaml_array "$component_file" ".platforms[]?")

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

  # Check that all dependencies are available (recursive check)
  local depends_on
  depends_on=$(read_yaml_array "$component_file" ".depends_on[]?") || return 0

  while IFS= read -r dep; do
    [[ -n "$dep" && "$dep" != "null" ]] || continue

    # Remove "components/" prefix if present
    dep="${dep#components/}"

    # Recursively check if dependency is available
    if ! is_component_available "$dep"; then
      return 1
    fi
  done < <(printf '%s\n' "$depends_on")

  return 0
}

# List all available components with their installation status
list_components() {
  step_header "Available Components"

  local core_components=()

  # Collect all components with descriptions
  for dir in "$MEOW_COMPONENTS_DIR"/*/; do
    if [[ -d "$dir" && -f "$dir/component.yaml" ]]; then
      local component_name
      component_name=$(basename "$dir")
      local description
      description=$(read_yaml_value "$dir/component.yaml" ".description")
      [[ -n "$description" && "$description" != "null" ]] || description="No description"
      core_components+=("$component_name:$description")
    fi
  done

  # Display components with status indicators
  if [[ ${#core_components[@]} -gt 0 ]]; then
    info "Core Components:"
    for component_info in "${core_components[@]}"; do
      local component_name="${component_info%%:*}"
      local description="${component_info#*:}"

      if is_component_installed "$component_name"; then
        success_tick_msg "$component_name - $description [INSTALLED]"
      elif is_component_available "$component_name"; then
        info "$component_name - $description"
      else
        warning "$component_name - $description [UNAVAILABLE]"
      fi
    done
  fi
}

# Check if component has repository configuration
# Args: $1 - component name
# Returns: 0 if component has repository config, 1 otherwise
has_component_repository_config() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1
  yaml_path_exists "$component_file" ".repository.url"
}

# Get repository URL from component configuration
# Args: $1 - component name
# Returns: Repository URL or empty if not configured
get_component_repository_url() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  read_yaml_value "$component_file" ".repository.url"
}

# Get repository branch or tag from component configuration
# Args: $1 - component name
# Returns: Branch/tag name, defaults to "main" if not specified
get_component_repository_branch() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  local branch tag
  branch=$(read_yaml_value "$component_file" ".repository.branch")
  tag=$(read_yaml_value "$component_file" ".repository.tag")

  if [[ -n "$tag" && "$tag" != "null" ]]; then
    echo "$tag"
  elif [[ -n "$branch" && "$branch" != "null" ]]; then
    echo "$branch"
  else
    echo "main"
  fi
}

# Clone component repository to installation directory
# Args:
#   $1 - component name
clone_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Remove existing repository if present
  if [[ -d "$installed_dir" ]]; then
    step_header "Removing existing repository for component: $component"
    rm -rf "$installed_dir"
  fi

  # Get repository configuration
  local repo_url branch_or_tag
  repo_url=$(get_component_repository_url "$component")
  branch_or_tag=$(get_component_repository_branch "$component")

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Cloning repository to .downloads/$component"
  fi

  # Clone repository with spinner
  mkdir -p "$(dirname "$installed_dir")"

  ui_spinner "Cloning $component repository" \
    --success "Repository cloned successfully" \
    --fail "Failed to clone repository" \
    git clone --depth 1 -b "$branch_or_tag" "$repo_url" "$installed_dir"

  return $?
}

# Update existing component repository
# Args:
#   $1 - component name
update_component_repository() {
  local component="$1"
  local installed_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Clone if repository doesn't exist
  if [[ ! -d "$installed_dir" ]]; then
    warning "Repository not found, cloning to .downloads/$component instead"
    clone_component_repository "$component"
    return $?
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Updating repository for component: $component"
  fi

  # Update repository using git with spinner
  ui_spinner "Updating $component repository" \
    --success "Repository updated successfully" \
    --fail "Failed to update repository" \
    sh -c "cd '$installed_dir' && git fetch && git reset --hard \"origin/\$(git rev-parse --abbrev-ref HEAD)\""

  if [[ $? -ne 0 ]]; then
    warning "Failed to update repository, trying to re-clone"
    clone_component_repository "$component"
    return $?
  fi

  return 0
}

# Clean up component repository
# Args:
#   $1 - component name
cleanup_component_repository() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 0

  # Skip if component doesn't have repository config
  if ! yaml_path_exists "$component_file" ".repository"; then
    return 0
  fi

  local repo_dir="${MEOW_DOWNLOADS_DIR}/${component}"

  # Remove repository directory if it exists
  if [[ -d "${repo_dir}/.git" ]]; then
    step_header "Cleaning up repository for $component"

    rm -rf "$repo_dir" || {
      error "Failed to remove repository directory: $repo_dir"
      return 1
    }

    success_tick_msg "Repository cleaned up for $component"
  fi
}

# Execute component setup script
setup_component() {
  local component="$1"
  local component_dir="${MEOW_INSTALLED_COMPONENTS_DIR}/${component}"
  local init_script="${component_dir}/scripts/setup.sh"

  if [[ -f "$init_script" ]]; then
    step_header "Running component setup: $component"
    [[ ! -x "$init_script" ]] && chmod +x "$init_script"
    if "$init_script" "$component" "$MEOW"; then
      success_tick_msg "Component setup completed successfully"
    else
      error "Component setup failed"
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
      step_header "Running component cleanup: $component"
    fi
    [[ ! -x "$cleanup_script" ]] && chmod +x "$cleanup_script"
    if "$cleanup_script" "$component" "$MEOW"; then
      verbose_success_tick_msg "Component cleanup completed successfully"
    else
      warning "Component cleanup failed"
      # Don't return error - cleanup failure shouldn't stop uninstallation
    fi
  fi
}

# Get all components that depend on a given component
get_components_depending_on() {
  local target_component="$1"
  local components=()

  # Check all installed components
  for component_symlink in "${MEOW_INSTALLED_COMPONENTS_DIR}"/*; do
    [[ -L "$component_symlink" ]] || continue

    local component_name
    component_name=$(basename "$component_symlink")

    local component_file="${component_symlink}/component.yaml"
    [[ -f "$component_file" ]] || continue

    # Check if this component depends on the target
    local deps
    deps=$(read_yaml_array "$component_file" ".depends_on[]?") || continue

    while IFS= read -r dep; do
      [[ -n "$dep" && "$dep" != "null" ]] || continue

      # Remove "components/" prefix if present
      dep="${dep#components/}"

      if [[ "$dep" == "$target_component" ]]; then
        components+=("$component_name")
        break
      fi
    done < <(printf '%s\n' "$deps")
  done

  printf '%s\n' "${components[@]}"
}

# Get all presets that depend on a given component
get_presets_depending_on() {
  # TODO move to proper module by usage
  local target_component="$1"
  get_presets_depending_on_excluding "$target_component" ""
}

# Get all presets that depend on a given component, excluding specified presets
get_presets_depending_on_excluding() {
  # TODO move to proper module by usage
  local target_component="$1"
  local exclude_preset="$2"
  local presets=()

  # Check all installed presets
  for preset_symlink in "${MEOW_INSTALLED_PRESETS_DIR}"/*; do
    [[ -L "$preset_symlink" ]] || continue

    local preset_name
    preset_name=$(basename "$preset_symlink")

    # Skip excluded preset
    [[ "$preset_name" == "$exclude_preset" ]] && continue

    # Get preset file path (new format only)
    local preset_file="${preset_symlink}/preset.yaml"
    [[ -f "$preset_file" ]] || continue

    # Check if this preset depends on the target component
    local required_deps
    required_deps=$(read_yaml_array "$preset_file" ".required[]?")

    # Check required dependencies
    while IFS= read -r dep; do
      [[ -n "$dep" && "$dep" != "null" ]] || continue
      if [[ "$dep" == "$target_component" ]]; then
        presets+=("$preset_name")
        break 2 # Break out of both loops
      fi
    done < <(printf '%s\n' "$required_deps")
  done

  printf '%s\n' "${presets[@]}"
}

get_component_dependencies() {
  local component="$1"
  local -n deps_array_ref="$2" # Use nameref to modify the passed array
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1

  # Read dependencies from component.yaml using our helper function
  local depends_on
  depends_on=$(read_yaml_array "$component_file" ".depends_on[]?") || return 0

  # Clear the array and populate it with dependencies
  deps_array_ref=()
  while IFS= read -r dep; do
    [[ -n "$dep" && "$dep" != "null" ]] || continue

    # Remove "components/" prefix if present
    dep="${dep#components/}"

    deps_array_ref+=("$dep")
  done < <(printf '%s\n' "$depends_on")

  return 0
}

# Public wrapper for installing components - handles session management
# Args:
#   $1+ - component names to install
#   --manual (optional) - mark components as manually installed (default: true)
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
      comp_is_manual="false"  # Dependencies are always automatic
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

# Internal recursive function for installing components
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

  # Mark component as installed (create symlink in .installed/components/)
  install_component_symlink "$component"

  # Setup symlinks (after component is available in .installed)
  setup_component_symlinks "$component"

  # Run component initialization if available (after component is marked as installed)
  setup_component "$component"

  success_tick_msg "Component '$component' installed successfully"
  unset MEOW_COMPONENT_MANUAL_INSTALL
  return 0
}

# Install component with topological dependency sorting
_install_component_internal() {
  local component="$1"
  local is_manual="${2:-true}"
  local is_dependency="${3:-false}"

  # If this is a dependency call (recursive), just install the single component
  if [[ "$is_dependency" == "true" ]]; then
    _install_single_component "$component" "$is_manual" "$is_dependency"
    return $?
  fi

  # For main component installation, use topological sorting
  local installation_order=()
  collect_all_dependencies_for_installation "$component" installation_order

  # Filter out already installed components for the summary
  local components_to_install=()
  for comp in "${installation_order[@]}"; do
    if ! is_component_installed "$comp"; then
      components_to_install+=("$comp")
    fi
  done

  # Show what will be installed
  if [[ ${#components_to_install[@]} -gt 1 ]]; then
    local main_comp_in_list=false
    for comp in "${components_to_install[@]}"; do
      if [[ "$comp" == "$component" ]]; then
        main_comp_in_list=true
        break
      fi
    done

    if [[ "$main_comp_in_list" == "true" ]]; then
      local dependencies_count=$((${#components_to_install[@]} - 1))
      if [[ $dependencies_count -gt 0 ]]; then
        action_msg "Will install $component with $dependencies_count dependencies"
      else
        action_msg "Will install $component (no new dependencies)"
      fi
    else
      action_msg "Will install dependencies for $component (already installed)"
    fi
  elif [[ ${#components_to_install[@]} -eq 1 ]]; then
    if [[ "${components_to_install[0]}" == "$component" ]]; then
      action_msg "Will install $component (no dependencies)"
    else
      action_msg "Will install dependency ${components_to_install[0]} for $component"
    fi
  else
    action_msg "$component and all dependencies are already installed"
  fi

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    if [[ ${#installation_order[@]} -gt 1 ]]; then
      step_header "Installation order (dependencies first):"
      for comp in "${installation_order[@]}"; do
        local status=""
        if is_component_installed "$comp"; then
          status=" (already installed)"
        fi
        if [[ "$comp" == "$component" ]]; then
          verbose_info "  ➤ $comp (main component)$status"
        else
          verbose_info "  ↪ $comp (dependency)$status"
        fi
      done
    fi
  else
    # Show compact list of what will be installed
    if [[ ${#components_to_install[@]} -gt 1 ]]; then
      local deps_list=""
      for comp in "${components_to_install[@]}"; do
        if [[ "$comp" != "$component" ]]; then
          if [[ -z "$deps_list" ]]; then
            deps_list="$comp"
          else
            deps_list="$deps_list, $comp"
          fi
        fi
      done
      if [[ -n "$deps_list" ]]; then
        indent_msg "New dependencies: $deps_list"
      fi
    fi
  fi

  # Install components in topological order
  for comp in "${installation_order[@]}"; do
    local comp_is_dependency=false
    local comp_is_manual="$is_manual"

    if [[ "$comp" != "$component" ]]; then
      comp_is_dependency=true
      comp_is_manual="false"  # Dependencies are always automatic
    fi

    if ! _install_single_component "$comp" "$comp_is_manual" "$comp_is_dependency"; then
      error "Failed to install component: $comp"
      return 1
    fi
  done

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

# Uninstall a component
# Args: $1 - component name, $2 - optional --force flag
# Side effects: Removes packages, removes symlinks, restores backups, removes component tracking
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

# Collect all dependencies starting from component in topological order for installation
# Args: $1 - component name, $2 - array name to store dependencies (including the component itself)
collect_all_dependencies_for_installation() {
  local component="$1"
  local -n result_ref="$2"
  local all_components=()

  # First, collect all dependencies recursively
  collect_dependencies_recursively_for_installation "$component" all_components

  # Add the main component itself at the end
  all_components+=("$component")

  # Then sort them topologically (dependencies first, then dependents)
  local sorted_deps=()
  topological_sort_for_installation all_components sorted_deps
  result_ref=("${sorted_deps[@]}")
}

# Recursively collect all dependencies of a component for installation
# Args: $1 - component name, $2 - array name to store all dependencies
collect_dependencies_recursively_for_installation() {
  local component="$1"
  local -n all_deps_ref="$2"

  _collect_deps_rec() {
    local comp="$1"
    local dependencies=()

    get_component_dependencies "$comp" dependencies

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]]; then
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
          _collect_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_deps_rec "$component"
}

# Topological sort for installation (dependencies before dependents)
# Args: $1 - array name with components, $2 - array name for sorted result
topological_sort_for_installation() {
  local -n input_array_ref="$1"
  local -n sorted_array_ref="$2"
  local remaining=("${input_array_ref[@]}")

  sorted_array_ref=()

  # Repeat until all components are sorted
  while [[ ${#remaining[@]} -gt 0 ]]; do
    local found_installable=false
    local new_remaining=()

    for component in "${remaining[@]}"; do
      local all_deps_satisfied=true

      # Check if all dependencies of this component are either:
      # 1. Already in sorted list (will be installed before)
      # 2. Not in remaining list (already installed or not needed)
      local component_deps=()
      get_component_dependencies "$component" component_deps

      for dep in "${component_deps[@]}"; do
        if [[ -n "$dep" ]]; then
          # Check if this dependency is still in remaining list
          local dep_in_remaining=false
          for remaining_comp in "${remaining[@]}"; do
            if [[ "$remaining_comp" == "$dep" ]]; then
              dep_in_remaining=true
              break
            fi
          done

          # If dependency is in remaining list, we can't install this component yet
          if [[ "$dep_in_remaining" == "true" ]]; then
            all_deps_satisfied=false
            break
          fi
        fi
      done

      if [[ "$all_deps_satisfied" == "true" ]]; then
        # All dependencies are satisfied, can install this component now
        sorted_array_ref+=("$component")
        found_installable=true
      else
        # Dependencies not satisfied, keep for next iteration
        new_remaining+=("$component")
      fi
    done

    remaining=("${new_remaining[@]}")

    # Prevent infinite loop if we have circular dependencies
    if [[ "$found_installable" == "false" && ${#remaining[@]} -gt 0 ]]; then
      warning "Circular dependencies detected among: ${remaining[*]}"
      # Add remaining components anyway to avoid infinite loop
      sorted_array_ref+=("${remaining[@]}")
      break
    fi
  done
}

# Collect all dependencies starting from component in topological order
# Args: $1 - component name, $2 - array name to store dependencies
collect_all_dependencies_topologically() {
  local component="$1"
  local -n result_ref="$2"
  local all_components=()

  # First, collect all dependencies recursively
  collect_dependencies_recursively "$component" all_components

  # Then sort them topologically (dependencies first, then dependents)
  local sorted_deps=()
  topological_sort_for_removal all_components sorted_deps
  result_ref=("${sorted_deps[@]}")
}

# Recursively collect all dependencies of a component
# Args: $1 - component name, $2 - array name to store all dependencies
collect_dependencies_recursively() {
  local component="$1"
  local -n all_deps_ref="$2"

  _collect_deps_rec() {
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
          _collect_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_deps_rec "$component"
}

# Filter dependencies to keep only those that can be safely removed
# Args: $1 - array name with all dependencies, $2 - array name for removable dependencies
filter_removable_dependencies() {
  local -n all_deps_ref="$1"
  local -n removable_ref="$2"
  local candidates=("${all_deps_ref[@]}")
  local changed=true

  # Iterate until no more components are removed from candidates
  while [[ "$changed" == "true" ]]; do
    changed=false
    local new_candidates=()

    for dep in "${candidates[@]}"; do
      local dep_copy="$dep"
      local should_keep=true


      if [[ -n "$dep_copy" ]]; then
        # Don't remove if manually installed
        if is_component_manually_installed "$dep_copy"; then
          should_keep=false
        fi

        # Remove if used by other installed components not in our current candidates list
        if [[ "$should_keep" == "true" ]]; then
          local other_dependents
          mapfile -t other_dependents < <(get_components_depending_on "$dep_copy")

          for dependent in "${other_dependents[@]}"; do
            if [[ -n "$dependent" ]]; then
              # Check if this dependent is in our current candidates list
              local in_candidates_list=false
              for candidate in "${candidates[@]}"; do
                if [[ "$dependent" == "$candidate" ]]; then
                  in_candidates_list=true
                  break
                fi
              done

              # If dependent is not in candidates list, we can't remove this dependency
              if [[ "$in_candidates_list" == "false" ]]; then
                should_keep=false
                break
              fi
            fi
          done
        fi

        # Remove if used by installed presets
        if [[ "$should_keep" == "true" ]]; then
          local preset_dependents
          mapfile -t preset_dependents < <(get_presets_depending_on "$dep_copy")

          for preset in "${preset_dependents[@]}"; do
            if [[ -n "$preset" ]]; then
              should_keep=false
              break
            fi
          done
        fi

        # If we should keep this component, add it to new candidates
        if [[ "$should_keep" == "true" ]]; then
          new_candidates+=("$dep_copy")
        else
          # Component was removed from candidates - need another iteration
          changed=true
        fi
      fi
    done

    candidates=("${new_candidates[@]}")
  done

  # Final candidates are the ones we can safely remove
  removable_ref=("${candidates[@]}")
}

# Filter dependencies with context of all components being removed
# Args: $1 - array name with dependencies to check, $2 - array name with all components being removed, $3 - array name for removable dependencies
filter_removable_dependencies_with_context() {
  local -n deps_to_check_ref="$1"
  local -n all_removing_ref="$2"
  local -n removable_ref="$3"
  local candidates=("${deps_to_check_ref[@]}")
  local changed=true

  # Iterate until no more components are removed from candidates
  while [[ "$changed" == "true" ]]; do
    changed=false
    local new_candidates=()

    for dep in "${candidates[@]}"; do
      local dep_copy="$dep"
      local should_keep=true


      if [[ -n "$dep_copy" ]]; then
        # Don't remove if manually installed
        if is_component_manually_installed "$dep_copy"; then
          should_keep=false
        fi

        # Check if used by other installed components not being removed
        if [[ "$should_keep" == "true" ]]; then
          local other_dependents
          mapfile -t other_dependents < <(get_components_depending_on "$dep_copy")

          for dependent in "${other_dependents[@]}"; do
            if [[ -n "$dependent" ]]; then
              # Check if this dependent is in our removal list (including requested components)
              local in_removal_list=false
              for removing_component in "${all_removing_ref[@]}"; do
                if [[ "$dependent" == "$removing_component" ]]; then
                  in_removal_list=true
                  break
                fi
              done

              # If dependent is not being removed, we can't remove this dependency
              if [[ "$in_removal_list" == "false" ]]; then
                should_keep=false
                break
              fi
            fi
          done
        fi

        # Check if used by installed presets
        if [[ "$should_keep" == "true" ]]; then
          local preset_dependents
          mapfile -t preset_dependents < <(get_presets_depending_on "$dep_copy")

          for preset in "${preset_dependents[@]}"; do
            if [[ -n "$preset" ]]; then
              should_keep=false
              break
            fi
          done
        fi

        # If we should keep this component, add it to new candidates
        if [[ "$should_keep" == "true" ]]; then
          new_candidates+=("$dep_copy")
        else
          # Component was removed from candidates - need another iteration
          changed=true
        fi
      fi
    done

    candidates=("${new_candidates[@]}")
  done

  # Final candidates are the ones we can safely remove
  removable_ref=("${candidates[@]}")
}

# Check if a dependency component should be removed
# Args: $1 - dependency component name
# Returns: 0 if should be removed, 1 if should be kept
should_remove_dependency() {
  local dep_component="$1"

  # Don't remove if not installed
  if ! is_component_installed "$dep_component"; then
    return 1
  fi

  # Don't remove if manually installed
  if is_component_manually_installed "$dep_component"; then
    return 1
  fi

  # Don't remove if used by other installed components
  local other_dependents
  mapfile -t other_dependents < <(get_components_depending_on "$dep_component")
  # Filter out empty elements
  local filtered_dependents=()
  for dep in "${other_dependents[@]}"; do
    if [[ -n "$dep" ]]; then
      filtered_dependents+=("$dep")
    fi
  done
  if [[ ${#filtered_dependents[@]} -gt 0 ]]; then
    return 1
  fi

  # Don't remove if used by installed presets
  local preset_dependents
  mapfile -t preset_dependents < <(get_presets_depending_on "$dep_component")
  # Filter out empty elements
  local filtered_presets=()
  for preset in "${preset_dependents[@]}"; do
    if [[ -n "$preset" ]]; then
      filtered_presets+=("$preset")
    fi
  done
  if [[ ${#filtered_presets[@]} -gt 0 ]]; then
    return 1
  fi

  # Can be safely removed
  return 0
}

# Collect all dependencies that can be safely removed recursively (fixed version)
# Args: $1 - component name, $2 - array name to store removable dependencies
collect_removable_dependencies_recursively_fixed() {
  local component="$1"
  local -n result_ref="$2"
  local dependencies=()

  get_component_dependencies "$component" dependencies

  for dep in "${dependencies[@]}"; do
    local dep_copy="$dep"
    if [[ -n "$dep_copy" ]] && should_remove_dependency "$dep_copy"; then
      # Check if already in the result array
      local already_added=false
      for existing in "${result_ref[@]}"; do
        if [[ "$existing" == "$dep_copy" ]]; then
          already_added=true
          break
        fi
      done

      if [[ "$already_added" == "false" ]]; then
        result_ref+=("$dep_copy")
        # Recursively collect dependencies of this dependency
        collect_removable_dependencies_recursively_fixed "$dep_copy" result_ref
      fi
    fi
  done
}

# Collect all dependencies that can be safely removed recursively
# Args: $1 - component name, outputs to stdout
collect_removable_dependencies_recursively() {
  local component="$1"
  local dependencies=()

  get_component_dependencies "$component" dependencies

  for dep in "${dependencies[@]}"; do
    if [[ -n "$dep" ]] && should_remove_dependency "$dep"; then
      echo "$dep"
      # Recursively collect dependencies of this dependency
      collect_removable_dependencies_recursively "$dep"
    fi
  done
}

# Sort components in topological order for removal (leaves first)
# Args: $1 - array name with components to sort, $2 - array name for sorted result
topological_sort_for_removal() {
  local -n input_array_ref="$1"
  local -n sorted_array_ref="$2"
  local remaining=("${input_array_ref[@]}")

  # Keep sorting until all components are processed
  while [[ ${#remaining[@]} -gt 0 ]]; do
    local found_leaf=false
    local new_remaining=()

    # Find components that are NOT dependencies of any other remaining component
    for component in "${remaining[@]}"; do
      local is_dependency_of_others=false

      # Check if this component is a dependency of any other remaining component
      for other_component in "${remaining[@]}"; do
        if [[ "$component" != "$other_component" ]]; then
          local other_deps=()
          get_component_dependencies "$other_component" other_deps

          for dep in "${other_deps[@]}"; do
            if [[ "$dep" == "$component" ]]; then
              is_dependency_of_others=true
              break 2
            fi
          done
        fi
      done

      if [[ "$is_dependency_of_others" == "false" ]]; then
        # This component is not a dependency of others, can be removed first
        sorted_array_ref+=("$component")
        found_leaf=true
      else
        # This component is still needed by others, keep it for next iteration
        new_remaining+=("$component")
      fi
    done

    remaining=("${new_remaining[@]}")

    # Prevent infinite loop if we have circular dependencies
    if [[ "$found_leaf" == "false" && ${#remaining[@]} -gt 0 ]]; then
      warning "Circular dependencies detected among: ${remaining[*]}"
      # Add remaining components anyway to avoid infinite loop
      sorted_array_ref+=("${remaining[@]}")
      break
    fi
  done
}

# Internal function to uninstall a component without dependency checks and cleanup
# Args: $1 - component name
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
