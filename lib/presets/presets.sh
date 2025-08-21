#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_PRESET_SYSTEM_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PRESET_SYSTEM_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/colors.sh"
source "${MEOW}/lib/core/ui.sh"
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

  # Check platform compatibility
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

# Install a preset (install all required components)
install_preset() {
  local preset="$1"

  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [[ ! -f "$preset_file" ]]; then
    error "Preset '$preset' not found"
    return 1
  fi

  if ! is_preset_available "$preset"; then
    error "Preset '$preset' is not available on this platform"
    return 1
  fi

  if is_preset_installed "$preset"; then
    warning "Preset '$preset' is already installed"
    return 0
  fi

  header "Installing preset: $preset"

  # Install required components
  step_header "Installing required components"
  local required_components
  required_components=$(get_preset_required_components "$preset")

  if [[ -n "$required_components" ]]; then
    # Convert components to array and install in one session
    local components_array=()
    while IFS= read -r component; do
      [[ -z "$component" ]] && continue
      components_array+=("$component")
    done <<<"$required_components"

    if [[ ${#components_array[@]} -gt 0 ]]; then
      info "Installing ${#components_array[@]} required components: ${components_array[*]}"
      if ! install_component --auto "${components_array[@]}"; then
        error "Failed to install required components"
        return 1
      fi
    fi
  fi

  # Mark preset as installed
  mkdir -p "$MEOW_INSTALLED_PRESETS_DIR"
  ln -s "${MEOW_PRESETS_DIR}/${preset}" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}"

  success_tick_msg "Preset '$preset' installed successfully"
  return 0
}

# Update a preset (update all installed components from the preset)
update_preset() {
  local preset="$1"

  if ! is_preset_installed "$preset"; then
    warning "Preset '$preset' is not installed"
    return 1
  fi

  header "Updating preset: $preset"

  # Update all required components that are installed
  step_header "Updating required components"
  local required_components
  required_components=$(get_preset_required_components "$preset")

  if [[ -n "$required_components" ]]; then
    # Convert components to array and update only installed ones in one session
    local components_to_update=()
    while IFS= read -r component; do
      [[ -z "$component" ]] && continue
      if is_component_installed "$component"; then
        components_to_update+=("$component")
      else
        info "Required component '$component' not installed, skipping"
      fi
    done <<<"$required_components"

    if [[ ${#components_to_update[@]} -gt 0 ]]; then
      info "Updating ${#components_to_update[@]} installed components: ${components_to_update[*]}"
      update_component "${components_to_update[@]}"
    fi
  fi

  success_tick_msg "Preset '$preset' updated successfully"
  return 0
}

# Get list of all installed components
get_all_installed_components() {
  local installed_components=()
  local components_dir="${MEOW}/.installed/components"

  # Check if the installed components directory exists
  if [[ ! -d "$components_dir" ]]; then
    return 0
  fi

  # Get all installed components from symlinks
  for component_symlink in "$components_dir"/*; do
    [[ -L "$component_symlink" ]] || continue
    local component_name
    component_name=$(basename "$component_symlink")
    installed_components+=("$component_name")
  done

  # Output components if any found
  if [[ ${#installed_components[@]} -gt 0 ]]; then
    printf '%s\n' "${installed_components[@]}"
  fi
}

# Update all installed components
update_all_installed_components() {
  local components
  components=($(get_all_installed_components))

  if [[ ${#components[@]} -eq 0 ]]; then
    info "No components are currently installed"
    return 0
  fi

  header "Updating all installed components"
  info "Found ${#components[@]} installed components: ${components[*]}"

  # Source components library and update all components
  source "${MEOW}/lib/components/components.sh"
  update_component "${components[@]}"
}

# List all available presets
list_presets() {
  header "Available Presets"

  for preset_dir in "${MEOW_PRESETS_DIR}"/*; do
    [[ ! -d "$preset_dir" ]] && continue

    local preset_name
    preset_name=$(basename "$preset_dir")
    local preset_file="${preset_dir}/preset.yaml"

    # Only show presets that have the new format
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

      info "${status}${preset_name} - ${description}${availability}"
    fi
  done
}
