#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/presets/presets.sh
# @brief: Preset management utilities for environment template deployment.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_PRESET_SYSTEM_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_PRESET_SYSTEM_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/colors.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/components/components.sh"

is_preset_installed() {
  local preset="$1"
  [ -L "${MEOW_INSTALLED_PRESETS_DIR}/${preset}" ]
}

is_preset_available() {
  local preset="$1"
  local preset_file
  preset_file=$(get_preset_file "$preset")

  [ -f "$preset_file" ] || return 1

  local platforms_str
  platforms_str=$(read_yaml_array "$preset_file" ".platforms[]?")

  if [ -n "$platforms_str" ] && [ "$platforms_str" != "null" ]; then
    local current_platform=""
    if [ "$IS_MACOS" = "true" ]; then
      current_platform="macos"
    elif [ "$IS_DEBIAN_BASED" = "true" ]; then
      current_platform="linux"
    elif [ "$IS_ALPINE" = "true" ]; then
      current_platform="linux"
    elif [ "$IS_ARCH" = "true" ]; then
      current_platform="linux"
    fi

    if [ -n "$current_platform" ]; then
      local platform_supported=false
      while IFS= read -r platform; do
        [ -n "$platform" ] && [ "$platform" != "null" ] || continue
        if [ "$platform" = "$current_platform" ]; then
          platform_supported=true
          break
        fi
      done < <(printf '%s\n' "$platforms_str")

      [ "$platform_supported" = "true" ] || return 1
    fi
  fi

  return 0
}

get_preset_file() {
  local preset="$1"
  echo "${MEOW_PRESETS_DIR}/${preset}/preset.yaml"
}

get_preset_required_components() {
  local preset="$1"
  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [ ! -f "$preset_file" ]; then
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "Debug: Preset file not found: %s" "$preset_file")" >&2
    fi
    return 1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Reading preset file: %s" "$preset_file")" >&2
    local file_content
    file_content=$(cat "$preset_file" 2>/dev/null || echo "Failed to read file")
    ui_verbose_info "$(_f "Debug: Preset file content: %s" "$file_content")" >&2
  fi

  # Use the shared YAML parsing logic with array parsing
  local required_components
  required_components=$(read_yaml_array "$preset_file" ".required[]")

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: final required components result: '%s'" "$required_components")" >&2
  fi

  echo "$required_components"
}

collect_preset_components_for_installation() {
  local preset="$1"

  local all_preset_components_str
  all_preset_components_str=$(get_preset_required_components "$preset")

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Raw preset components string: '%s'" "$all_preset_components_str")" >&2
  fi

  local preset_required_array=()
  if [ -n "$all_preset_components_str" ]; then
    while IFS= read -r component; do
      [ -z "$component" ] && continue
      preset_required_array+=("$component")
    done <<<"$all_preset_components_str"
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Preset required array contains %d components: %s" "${#preset_required_array[@]}" "$(printf '%s ' "${preset_required_array[@]}")")" >&2
  fi

  local collected_unique_components=()
  local deps_output

  for component_name in "${preset_required_array[@]}"; do
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "Debug: Processing component '%s'" "$component_name")" >&2
    fi

    deps_output=$(collect_all_dependencies_for_installation "$component_name")

    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "Debug: Dependencies for '%s': '%s'" "$component_name" "$deps_output")" >&2
    fi

    if [ -n "$deps_output" ]; then
      while IFS= read -r dep_comp; do
        [ -z "$dep_comp" ] && continue
        local already_in_list=false
        for existing_comp in "${collected_unique_components[@]}"; do
          if [ "$existing_comp" = "$dep_comp" ]; then
            already_in_list=true
            break
          fi
        done
        if [ "$already_in_list" = "false" ]; then
          collected_unique_components+=("$dep_comp")
        fi
      done <<<"$deps_output"
    fi
  done

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Collected unique components array contains %d components: %s" "${#collected_unique_components[@]}" "$(printf '%s ' "${collected_unique_components[@]}")")" >&2
  fi

  if [ ${#collected_unique_components[@]} -gt 0 ]; then
    topological_sort_for_installation "${collected_unique_components[@]}"
  fi
}

install_preset() {
  local preset="$1"
  local force_flag="${2:-}"

  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [ ! -f "$preset_file" ]; then
    ui_error "$(_f "Preset '%s' not found." "$preset")"
    return 1
  fi

  if ! is_preset_available "$preset"; then
    ui_error "$(_f "Preset '%s' is not available on this platform." "$preset")"
    return 1
  fi

  if is_preset_installed "$preset"; then
    ui_warning "$(_f "Preset '%s' is already installed." "$preset")"
    return 0
  fi

  ui_title "$(_f "==> Installing Preset: %s" "$preset")"

  local installation_order_str
  installation_order_str=$(collect_preset_components_for_installation "$preset")

  local installation_order=()
  if [ -n "$installation_order_str" ]; then
    while IFS= read -r comp; do
      installation_order+=("$comp")
    done <<<"$installation_order_str"
  fi

  if [ ${#installation_order[@]} -eq 0 ]; then
    ui_info "No components to install for this preset."

    # Debug output to help diagnose the issue
    if [ "$MEOW_VERBOSE" = "true" ]; then
      local preset_components_debug
      preset_components_debug=$(get_preset_required_components "$preset")
      ui_verbose_info "$(_f "Debug: Required components from preset YAML: %s" "$preset_components_debug")"

      if [ -n "$preset_components_debug" ]; then
        ui_verbose_info "Debug: Checking individual component installation status:"
        while IFS= read -r comp_debug; do
          [ -z "$comp_debug" ] && continue
          if is_component_installed "$comp_debug"; then
            ui_verbose_info "$(_f "  - %s: already installed" "$comp_debug")"
          else
            ui_verbose_info "$(_f "  - %s: NOT installed" "$comp_debug")"
          fi
        done <<<"$preset_components_debug"
      fi
    fi
  else
    local preset_components_str
    preset_components_str=$(get_preset_required_components "$preset")
    local preset_components_array=()

    if [ -n "$preset_components_str" ]; then
      while IFS= read -r component; do
        [ -z "$component" ] && continue
        preset_components_array+=("$component")
      done <<<"$preset_components_str"
    fi

    local components_to_install=()
    for comp in "${installation_order[@]}"; do
      if [ "$force_flag" = "--force" ] || ! is_component_installed "$comp"; then
        components_to_install+=("$comp")
      fi
    done

    ui_action_start "$(_f "Preparing to install %d preset components with dependencies." "${#preset_components_array[@]}")"
    if [ ${#components_to_install[@]} -gt 0 ]; then
      ui_indent "$(_f "Total components to install: %d" "${#components_to_install[@]}")"

      if [ "$MEOW_VERBOSE" = "true" ]; then
        ui_step_header "Installation order:"
        for comp in "${installation_order[@]}"; do
          local status=""
          if is_component_installed "$comp"; then
            status=" (already installed)"
          fi

          local is_preset_component=false
          for preset_comp in "${preset_components_array[@]}"; do
            if [ "$preset_comp" = "$comp" ]; then
              is_preset_component=true
              break
            fi
          done

          if [ "$is_preset_component" = "true" ]; then
            ui_verbose_info "  ➤ %s (preset component)%s" "$comp" "$status"
          else
            ui_verbose_info "  ↪ %s (dependency)%s" "$comp" "$status"
          fi
        done
      else
        local deps_list=""
        local preset_comp_list=""
        for comp in "${components_to_install[@]}"; do
          local is_preset_component=false
          for preset_comp in "${preset_components_array[@]}"; do
            if [ "$preset_comp" = "$comp" ]; then
              is_preset_component=true
              break
            fi
          done

          if [ "$is_preset_component" = "true" ]; then
            if [ -z "$preset_comp_list" ]; then
              preset_comp_list="$comp"
            else
              preset_comp_list="$preset_comp_list, $comp"
            fi
          else
            if [ -z "$deps_list" ]; then
              deps_list="$comp"
            else
              deps_list="$deps_list, $comp"
            fi
          fi
        done

        if [ -n "$preset_comp_list" ]; then
          ui_indent "$(_f "Preset components: %s" "$preset_comp_list")"
        fi
        if [ -n "$deps_list" ]; then
          ui_indent "$(_f "Dependencies: %s" "$deps_list")"
        fi
      fi
    else
      ui_indent "All components already installed for this preset."
    fi

    local force_install="false"
    if [ "$force_flag" = "--force" ]; then
      force_install="true"
    fi

    _initialize_session || {
      ui_error "Session initialization failed."
      return 1
    }

    declare -ga MEOW_INSTALLING_COMPONENTS=()
    local installed_this_session=()

    local install_success=true
    for component in "${installation_order[@]}"; do
      if ! _install_single_component "$component" false false "$force_install"; then
        ui_error "$(_f "Failed to install component '%s' for preset '%s'." "$component" "$preset")"
        install_success=false
        break
      fi

      if [ "$MEOW_LAST_COMPONENT_CHANGED" = "true" ]; then
        installed_this_session+=("$component")
      fi
    done

    if [ "$install_success" != "true" ]; then
      if [ ${#installed_this_session[@]} -gt 0 ]; then
        ui_warning "Rolling back partially installed components for preset '$preset'..."
        for ((i = ${#installed_this_session[@]} - 1; i >= 0; i--)); do
          local rollback_comp="${installed_this_session[$i]}"
          ui_warning "$(_f "Rolling back '%s'." "$rollback_comp")"
          _uninstall_single_component "$rollback_comp" "true" >/dev/null 2>&1 || true
        done
      fi
      _finalize_session
      unset MEOW_INSTALLING_COMPONENTS
      ui_error "$(_f "Failed to install all required components for preset '%s'." "$preset")"
      return 1
    fi

    _finalize_session
    unset MEOW_INSTALLING_COMPONENTS
  fi

  if is_dry_run; then
    dry_run_file_operation "create_symlink" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}" "${MEOW_PRESETS_DIR}/${preset}"
    ui_success "$(_f "Preset '%s' would be installed (dry run)." "$preset")"
  else
    mkdir -p "$MEOW_INSTALLED_PRESETS_DIR"
    ln -s "${MEOW_PRESETS_DIR}/${preset}" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}"
    ui_success "$(_f "Preset '%s' installed successfully." "$preset")"
  fi

  return 0
}

update_preset() {
  local preset="$1"

  if ! is_preset_installed "$preset"; then
    ui_warning "$(_f "Preset '%s' is not installed." "$preset")"
    return 1
  fi

  ui_header "$(_f "Updating Preset: %s" "$preset")"

  ui_step_header "Updating required components."
  local required_components_str
  required_components_str=$(get_preset_required_components "$preset")

  if [ -n "$required_components_str" ]; then
    local components_to_update=()
    while IFS= read -r component; do
      [ -z "$component" ] && continue
      if is_component_installed "$component"; then
        components_to_update+=("$component")
      else
        ui_info "$(_f "Required component '%s' not installed, skipping update." "$component")"
      fi
    done <<<"$required_components_str"

    if [ ${#components_to_update[@]} -gt 0 ]; then
      ui_info "$(_f "Updating %d installed components: %s" "${#components_to_update[@]}" "$(printf '%s ' "${components_to_update[@]}")")"
      update_component "${components_to_update[@]}"
    else
      ui_info "No installed components to update for preset '$preset'."
    fi
  else
    ui_info "No required components found for preset '$preset'."
  fi

  ui_action_success "$(_f "Preset '%s' updated successfully." "$preset")"
  return 0
}

get_all_installed_components() {
  local components_dir="${MEOW_INSTALLED_COMPONENTS_DIR}"

  if [ ! -d "$components_dir" ]; then
    return 0
  fi

  for component_symlink in "$components_dir"/*; do
    [ -L "$component_symlink" ] || continue
    basename "$component_symlink"
  done
}

update_all_installed_components() {
  local components_str
  components_str=$(get_all_installed_components)

  local components=()
  if [ -n "$components_str" ]; then
    while IFS= read -r comp; do
      components+=("$comp")
    done <<<"$components_str"
  fi

  if [ ${#components[@]} -eq 0 ]; then
    ui_info "No components are currently installed."
    return 0
  fi

  ui_header "Updating all installed components."
  ui_info "$(_f "Found %d installed components: %s" "${#components[@]}" "$(printf '%s ' "${components[@]}")")"

  update_component "${components[@]}"
  ui_action_success "All installed components updated successfully."
  return 0
}

list_presets() {
  ui_header "Available Presets"

  for preset_dir in "${MEOW_PRESETS_DIR}"/*; do
    [ ! -d "$preset_dir" ] && continue

    local preset_name
    preset_name=$(basename "$preset_dir")
    local preset_file="${preset_dir}/preset.yaml"

    if [ -f "$preset_file" ]; then
      local description
      description=$(read_yaml_value "$preset_file" ".description")

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

uninstall_preset() {
  local preset="$1"
  local force_flag="${2:-}"

  if ! is_preset_installed "$preset"; then
    ui_error "$(_f "Preset '%s' is not installed." "$preset")"
    return 1
  fi

  local preset_file
  preset_file=$(get_preset_file "$preset")

  if [ ! -f "$preset_file" ]; then
    ui_error "$(_f "Preset '%s' not found." "$preset")"
    return 1
  fi

  ui_action_start "$(_f "==> Uninstalling Preset: %s" "$preset")"

  local preset_components_str
  preset_components_str=$(get_preset_required_components "$preset")
  local preset_components_array=()

  if [ -n "$preset_components_str" ]; then
    while IFS= read -r component; do
      [ -z "$component" ] && continue
      if is_component_installed "$component"; then
        preset_components_array+=("$component")
      fi
    done <<<"$preset_components_str"
  fi

  if [ ${#preset_components_array[@]} -eq 0 ]; then
    ui_info "$(_f "No installed components to uninstall for preset '%s'." "$preset")"
  else
    local preset_name="$preset"

    local multiple_uninstall_order_str
    multiple_uninstall_order_str=$(collect_multiple_components_for_uninstall "${preset_components_array[@]}" --filter-source --exclude-preset="$preset_name")

    local multiple_uninstall_order=()
    if [ -n "$multiple_uninstall_order_str" ]; then
      while IFS= read -r comp; do
        multiple_uninstall_order+=("$comp")
      done <<<"$multiple_uninstall_order_str"
    fi

    if [ ${#multiple_uninstall_order[@]} -gt 0 ]; then
      local args=("${multiple_uninstall_order[@]}")
      if [ "$force_flag" = "--force" ]; then
        args+=("--force")
      fi
      args+=("--exclude-preset=$preset_name")

      if ! uninstall_component "${args[@]}"; then
        ui_error "$(_f "Failed to uninstall components for preset '%s'." "$preset_name")"
        return 1
      fi
    else
      ui_info "$(_f "No components associated with preset '%s' can be safely uninstalled (they are used by other presets or manually installed)." "$preset_name")"
    fi
  fi

  remove_preset_tracking "$preset"

  ui_success "$(_f "Preset '%s' uninstalled successfully." "$preset")"
  return 0
}

remove_preset_tracking() {
  local preset="$1"

  if is_dry_run; then
    dry_run_file_operation "remove_symlink" "${MEOW_INSTALLED_PRESETS_DIR}/${preset}"
  else
    rm -rf "${MEOW_INSTALLED_PRESETS_DIR:?}/${preset}"
  fi
}

uninstall_all() {
  local components_str
  components_str=$(get_all_installed_components)

  local components=()
  if [ -n "$components_str" ]; then
    while IFS= read -r comp; do
      components+=("$comp")
    done <<<"$components_str"
  fi

  if [ ${#components[@]} -eq 0 ]; then
    ui_info "No components are currently installed."
  else
    ui_header "Uninstalling all installed components."
    ui_info "$(_f "Found %d installed components: %s" "${#components[@]}" "$(printf '%s ' "${components[@]}")")"

    uninstall_component "${components[@]}" --force
  fi

  ui_step_header "Cleaning up installation tracking."

  if is_dry_run; then
    dry_run_file_operation "remove_directory" "${MEOW_INSTALLED_COMPONENTS_DIR}"
    dry_run_file_operation "remove_directory" "${MEOW_INSTALLED_PRESETS_DIR}"
    dry_run_file_operation "remove_directory" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}"
    dry_run_file_operation "remove_directory" "${MEOW_DOWNLOADS_DIR}"
    ui_success "All components would be uninstalled and installation tracking cleaned (dry run)."
  else
    if [ -d "${MEOW_INSTALLED_COMPONENTS_DIR}" ]; then
      rm -rf "${MEOW_INSTALLED_COMPONENTS_DIR:?}"
      ui_verbose_info "Removed components tracking directory: %s" "${MEOW_INSTALLED_COMPONENTS_DIR}"
    fi

    if [ -d "${MEOW_INSTALLED_PRESETS_DIR}" ]; then
      rm -rf "${MEOW_INSTALLED_PRESETS_DIR:?}"
      ui_verbose_info "Removed presets tracking directory: %s" "${MEOW_INSTALLED_PRESETS_DIR}"
    fi

    if [ -d "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}" ]; then
      rm -rf "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR:?}"
      ui_verbose_info "Removed manual installation tracking directory: %s" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}"
    fi
    if [ -d "${MEOW_DOWNLOADS_DIR}" ]; then
      rm -rf "${MEOW_DOWNLOADS_DIR:?}"
      ui_verbose_info "Removed downloads cache directory: %s" "${MEOW_DOWNLOADS_DIR}"
    fi
    ui_success "All components uninstalled and installation tracking cleaned."
  fi
}
