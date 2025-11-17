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
# @file: lib/components/operations.sh
# @brief: High-level component installation, update, and collection operations.
# @author: Andrew Vasilyev
# @license: MIT
#
MEOW_INSTALLING_COMPONENTS=()
MEOW_UPDATED_COMPONENTS=()
MEOW_LAST_COMPONENT_CHANGED="false"

if [[ -n "${_LIB_COMPONENTS_OPERATIONS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_OPERATIONS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/components/core.sh"
source "${MEOW}/lib/components/packages.sh"
source "${MEOW}/lib/components/repository.sh"
source "${MEOW}/lib/components/dependencies.sh"
source "${MEOW}/lib/components/symlinks.sh"

collect_multiple_components_for_installation() {
  local components_array=("$@")
  local collected_components=()

  for component in "${components_array[@]}"; do
    local component_and_deps_str
    component_and_deps_str="$(collect_all_dependencies_for_installation "$component")" || {
      ui_error "$(_f "Failed to collect dependencies for component: %s" "$component")"
      return 1
    }

    local component_and_deps=()
    while IFS= read -r comp; do
      component_and_deps+=("$comp")
    done <<<"$component_and_deps_str"

    for comp in "${component_and_deps[@]}"; do
      local already_added="false"
      for existing in "${collected_components[@]}"; do
        if [[ "$existing" = "$comp" ]]; then
          already_added="true"
          break
        fi
      done
      if [[ "$already_added" = "false" ]]; then
        collected_components+=("$comp")
      fi
    done
  done

  local sorted_components_str
  sorted_components_str="$(topological_sort_for_installation "${collected_components[@]}")" || {
    ui_error "Failed to topologically sort components for installation."
    return 1
  }
  echo "$sorted_components_str"
}

install_component() {
  local components=()
  local is_manual="true"
  local force_install="false"

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
      --force)
        force_install="true"
        shift
        ;;
      *)
        components+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_error "No components specified for installation."
    return 1
  fi

  local multiple_installation_order_str
  multiple_installation_order_str="$(collect_multiple_components_for_installation "${components[@]}")" || {
    ui_error "Failed to determine installation order."
    return 1
  }

  local multiple_installation_order=()
  while IFS= read -r comp; do
    multiple_installation_order+=("$comp")
  done <<<"$multiple_installation_order_str"

  if [[ ${#multiple_installation_order[@]} -eq 0 ]]; then
    ui_info "No new components or dependencies to install."
    return 0
  fi

  local components_to_install=()
  for comp in "${multiple_installation_order[@]}"; do
    if ! is_component_installed "$comp"; then
      components_to_install+=("$comp")
    fi
  done

  local plural_suffix=""
  if [[ ${#components[@]} -gt 1 ]]; then
    plural_suffix="s"
  fi
  ui_action_start "$(_f "Will install %d component%s with dependencies" "${#components[@]}" "$plural_suffix")"

  if [[ ${#components_to_install[@]} -gt 0 ]]; then
    ui_indent "$(_f "Total components to install: %d" "${#components_to_install[@]}")"

    if [[ "$MEOW_VERBOSE" = "true" ]]; then
      ui_step_header "Installation order:"
      for comp in "${multiple_installation_order[@]}"; do
        local status=""
        if is_component_installed "$comp"; then
          status=" (already installed)"
        fi

        local is_requested_component="false"
        for requested_comp in "${components[@]}"; do
          if [[ "$requested_comp" = "$comp" ]]; then
            is_requested_component="true"
            break
          fi
        done

        if [[ "$is_requested_component" = "true" ]]; then
          ui_verbose_info "$(_f "  ➤ %s (requested component)%s" "$comp" "$status")"
        else
          ui_verbose_info "$(_f "  ↪ %s (dependency)%s" "$comp" "$status")"
        fi
      done
    else
      local deps_list=""
      local requested_comp_list=""
      for comp in "${multiple_installation_order[@]}"; do
        local is_requested_component="false"
        for requested_comp in "${components[@]}"; do
          if [[ "$requested_comp" = "$comp" ]]; then
            is_requested_component="true"
            break
          fi
        done

        if [[ "$is_requested_component" = "true" ]]; then
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
        ui_indent "$(_f "Requested components: %s" "$requested_comp_list")"
      fi
      if [[ -n "$deps_list" ]]; then
        ui_indent "$(_f "New dependencies: %s" "$deps_list")"
      fi
    fi
  else
    ui_indent "All requested components and their dependencies are already installed."
  fi

  _initialize_session || {
    ui_error "Session initialization failed."
    return 1
  }

  MEOW_INSTALLING_COMPONENTS=()
  local installed_this_session=()

  local install_success="true"
  for component in "${multiple_installation_order[@]}"; do
    local comp_is_manual="$is_manual"
    local comp_is_dependency="false"

    local is_requested_component="false"
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" = "$component" ]]; then
        is_requested_component="true"
        break
      fi
    done

    if [[ "$is_requested_component" = "false" ]]; then
      comp_is_dependency="true"
      comp_is_manual="false"
    fi

    if ! _install_single_component "$component" "$comp_is_manual" "$comp_is_dependency" "$force_install"; then
      ui_error "$(_f "Failed to install component: %s" "$component")"
      install_success="false"
      break
    fi

    if [[ "$MEOW_LAST_COMPONENT_CHANGED" = "true" ]]; then
      installed_this_session+=("$component")
    fi
  done

  if [[ "$install_success" != "true" ]]; then
    if [[ ${#installed_this_session[@]} -gt 0 ]]; then
      ui_warning "Rolling back partially installed components..."
      for ((i = ${#installed_this_session[@]} - 1; i >= 0; i--)); do
        local rollback_comp="${installed_this_session[$i]}"
        ui_warning "$(_f "Rolling back '%s'." "$rollback_comp")"
        _uninstall_single_component "$rollback_comp" "true" >/dev/null 2>&1 || true
      done
    fi
    _finalize_session
    MEOW_INSTALLING_COMPONENTS=()
    return 1
  fi

  _finalize_session
  MEOW_INSTALLING_COMPONENTS=()
  return 0
}

_install_single_component() {
  local component="$1"
  local is_manual="${2:-true}"
  local is_dependency="${3:-false}"
  local force_install="${4:-false}"
  MEOW_LAST_COMPONENT_CHANGED="false"

  local already_installing="false"
  for installing_comp in "${MEOW_INSTALLING_COMPONENTS[@]}"; do
    if [[ "$installing_comp" = "$component" ]]; then
      already_installing="true"
      break
    fi
  done

  if [[ "$already_installing" = "true" ]]; then
    ui_verbose_info "$(_f "Component '%s' already being installed in this session, skipping." "$component")"
    return 0
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    ui_error "$(_f "Component '%s' definition file not found at %s." "$component" "$component_file")"
    return 1
  fi

  if ! is_component_available "$component"; then
    ui_error "$(_f "Component '%s' is not available for installation." "$component")"
    return 1
  fi

  if is_component_installed "$component"; then
    if [[ "$force_install" = "true" ]]; then
      ui_warning "$(_f "Component '%s' already installed. Reinstalling due to --force." "$component")"
      _uninstall_single_component "$component" "true" "true" >/dev/null 2>&1 || true
    elif [[ "$is_manual" = "true" ]] && ! is_component_manually_installed "$component"; then
      mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR" || {
        ui_error "$(_f "Failed to create directory for manual installations: %s" "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR")"
        return 1
      }
      ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" || {
        ui_error "$(_f "Failed to mark component '%s' as manually installed (symlink creation failed)." "$component")"
        return 1
      }
      ui_action_success "$(_f "Component '%s' is now marked as manually installed." "$component")"
    else
      ui_verbose_info "$(_f "Component '%s' is already installed." "$component")"
      MEOW_LAST_COMPONENT_CHANGED="false"
      return 0
    fi
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_component_installing "$component"
  else
    if [[ "$is_dependency" = "true" ]]; then
      ui_dependency "$(_f "Installing dependency: %s" "$component")"
    else
      ui_component_installing "$component"
    fi
  fi

  MEOW_INSTALLING_COMPONENTS+=("$component")

  export MEOW_COMPONENT_MANUAL_INSTALL="$is_manual"
  if ! install_component_packages "$component"; then
    ui_error "$(_f "Failed to install packages for component: %s" "$component")"
    return 1
  fi

  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" = "true" ]]; then
      ui_step_header "$(_f "Cloning repository for %s" "$component")"
    fi

    if ! clone_component_repository "$component"; then
      ui_error "$(_f "Failed to clone repository for component: %s" "$component")"
      return 1
    fi
  fi

  setup_component "$component"

  install_component_symlink "$component"

  setup_component_symlinks "$component"
  MEOW_LAST_COMPONENT_CHANGED="true"

  _icon_msg_core "${GREEN}✓ " "$(_f "Component installed: %s" "$component")"
  unset MEOW_COMPONENT_MANUAL_INSTALL
  return 0
}

collect_multiple_components_for_update() {
  local components_array=("$@")
  local collected_components=()

  for component in "${components_array[@]}"; do
    local component_and_deps_str
    component_and_deps_str="$(collect_installed_dependencies_for_update "$component")" || {
      ui_error "$(_f "Failed to collect installed dependencies for update for component: %s" "$component")"
      return 1
    }

    local component_and_deps=()
    while IFS= read -r comp; do
      component_and_deps+=("$comp")
    done <<<"$component_and_deps_str"

    for comp in "${component_and_deps[@]}"; do
      local already_added="false"
      for existing in "${collected_components[@]}"; do
        if [[ "$existing" = "$comp" ]]; then
          already_added="true"
          break
        fi
      done
      if [[ "$already_added" = "false" ]]; then
        collected_components+=("$comp")
      fi
    done
  done

  local sorted_components_str
  sorted_components_str="$(topological_sort_for_installation "${collected_components[@]}")" || {
    ui_error "Failed to topologically sort components for update."
    return 1
  }
  echo "$sorted_components_str"
}

update_component() {
  local components=("$@")

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_error "No components specified for update."
    return 1
  fi

  local missing_components=()
  for component in "${components[@]}"; do
    if ! is_component_installed "$component"; then
      missing_components+=("$component")
    fi
  done

  if [[ ${#missing_components[@]} -gt 0 ]]; then
    for missing in "${missing_components[@]}"; do
      ui_error "$(_f "Component '%s' is not installed and cannot be updated." "$missing")"
    done
    return 1
  fi

  reset_package_update_cache

  local multiple_update_order_str
  multiple_update_order_str="$(collect_multiple_components_for_update "${components[@]}")" || {
    ui_error "Failed to determine update order."
    return 1
  }

  local multiple_update_order=()
  while IFS= read -r comp; do
    multiple_update_order+=("$comp")
  done <<<"$multiple_update_order_str"

  if [[ ${#multiple_update_order[@]} -eq 0 ]]; then
    ui_info "No components to update."
    return 0
  fi

  local plural_suffix=""
  if [[ ${#components[@]} -gt 1 ]]; then
    plural_suffix="s"
  fi
  ui_action_start "$(_f "Will update %d component%s with dependencies" "${#components[@]}" "$plural_suffix")"
  ui_indent "$(_f "Total components to update: %d" "${#multiple_update_order[@]}")"

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "Update order:"
    for comp in "${multiple_update_order[@]}"; do
      local is_requested_component="false"
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" = "$comp" ]]; then
          is_requested_component="true"
          break
        fi
      done

      if [[ "$is_requested_component" = "true" ]]; then
        ui_verbose_info "$(_f "  ➤ %s (requested component)" "$comp")"
      else
        ui_verbose_info "$(_f "  ↪ %s (dependency)" "$comp")"
      fi
    done
  else
    local deps_list=""
    local requested_comp_list=""
    for comp in "${multiple_update_order[@]}"; do
      local is_requested_component="false"
      for requested_comp in "${components[@]}"; do
        if [[ "$requested_comp" = "$comp" ]]; then
          is_requested_component="true"
          break
        fi
      done

      if [[ "$is_requested_component" = "true" ]]; then
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
      ui_indent "$(_f "Requested components: %s" "$requested_comp_list")"
    fi
    if [[ -n "$deps_list" ]]; then
      ui_indent "$(_f "Dependencies: %s" "$deps_list")"
    fi
  fi

  _initialize_session || {
    ui_error "Session initialization failed."
    return 1
  }

  MEOW_UPDATED_COMPONENTS=()

  for component in "${multiple_update_order[@]}"; do
    local comp_is_dependency="false"

    local is_requested_component="false"
    for requested_comp in "${components[@]}"; do
      if [[ "$requested_comp" = "$component" ]]; then
        is_requested_component="true"
        break
      fi
    done

    if [[ "$is_requested_component" = "false" ]]; then
      comp_is_dependency="true"
    fi

    if ! _update_single_component "$component" "$comp_is_dependency"; then
      ui_warning "$(_f "Failed to update component: %s, continuing with other components." "$component")"
    fi
  done

  _finalize_session
  MEOW_UPDATED_COMPONENTS=()

  return 0
}

collect_installed_dependencies_for_update() {
  local component="$1"
  local all_components_str

  all_components_str="$(collect_installed_dependencies_recursively "$component")" || {
    ui_error "$(_f "Failed to recursively collect installed dependencies for component: %s" "$component")"
    return 1
  }

  local all_components=()
  while IFS= read -r comp; do
    all_components+=("$comp")
  done <<<"$all_components_str"

  local already_added="false"
  for existing in "${all_components[@]}"; do
    if [[ "$existing" = "$component" ]]; then
      already_added="true"
      break
    fi
  done
  if [[ "$already_added" = "false" ]]; then
    all_components+=("$component")
  fi

  local sorted_deps_str
  sorted_deps_str="$(topological_sort_for_installation "${all_components[@]}")" || {
    ui_error "Failed to topologically sort collected dependencies for update."
    return 1
  }
  echo "$sorted_deps_str"
}

collect_installed_dependencies_recursively() {
  local component="$1"
  local all_deps_output=()

  _collect_installed_deps_rec() {
    local comp="$1"

    local dependencies=()
    local dep_str
    dep_str="$(get_component_dependencies "$comp")" || {
      ui_warning "$(_f "Failed to get dependencies for '%s', some dependencies might be missed." "$comp")"
      return 0
    }

    while IFS= read -r dep; do
      dependencies+=("$dep")
    done <<<"$dep_str"

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]] && is_component_installed "$dep"; then
        local already_added="false"
        for existing in "${all_deps_output[@]}"; do
          if [[ "$existing" = "$dep" ]]; then
            already_added="true"
            break
          fi
        done

        if [[ "$already_added" = "false" ]]; then
          all_deps_output+=("$dep")
          _collect_installed_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_installed_deps_rec "$component"

  for dep in "${all_deps_output[@]}"; do
    echo "$dep"
  done
}

_update_single_component() {
  local component="$1"
  local is_dependency="${2:-false}"

  local already_updated="false"
  for updated_comp in "${MEOW_UPDATED_COMPONENTS[@]}"; do
    if [[ "$updated_comp" = "$component" ]]; then
      already_updated="true"
      break
    fi
  done

  if [[ "$already_updated" = "true" ]]; then
    ui_verbose_info "$(_f "Component '%s' already updated in this session, skipping." "$component")"
    return 0
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [[ ! -f "$component_file" ]]; then
    ui_error "$(_f "Component '%s' definition file not found at %s." "$component" "$component_file")"
    return 1
  fi

  if ! is_component_installed "$component"; then
    ui_verbose_info "$(_f "Component '%s' is not installed, skipping update." "$component")"
    return 0
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_component_updating "$component"
  else
    if [[ "$is_dependency" = "true" ]]; then
      ui_dependency "$(_f "Updating dependency: %s" "$component")"
    else
      ui_component_updating "$component"
    fi
  fi

  MEOW_UPDATED_COMPONENTS+=("$component")

  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" = "true" ]]; then
      ui_step_header "$(_f "Updating repository for %s" "$component")"
    fi
    if update_component_repository "$component"; then
      ui_verbose_action_success "Repository updated successfully."
    else
      ui_warning "$(_f "Repository update failed for %s, continuing with package updates." "$component")"
    fi
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Updating packages for %s" "$component")"
  fi
  if update_component_packages "$component"; then
    ui_verbose_action_success "Packages updated successfully."
  else
    ui_warning "$(_f "Some package updates may have failed for %s." "$component")"
  fi

  setup_component "$component"

  setup_component_symlinks "$component"

  _icon_msg_core "${CYAN}✓ " "$(_f "Component updated: %s" "$component")"

  return 0
}

collect_multiple_components_for_uninstall() {
  local all_args=("$@")
  local filter_source_components="false"
  local skip_preset_checks="false"
  local exclude_preset=""

  local components_array=()
  local i
  local num_args=${#all_args[@]}
  local components_start_index=0

  for ((i = num_args - 1; i >= 0; i--)); do
    local current_arg="${all_args[$i]}"
    case "$current_arg" in
      "--filter-source")
        filter_source_components="true"
        ;;
      "--skip-preset-checks")
        skip_preset_checks="true"
        ;;
      --exclude-preset=*)
        exclude_preset="${current_arg#--exclude-preset=}"
        ;;
      *)
        components_start_index=$((i + 1))
        break
        ;;
    esac
    if [[ $i -eq 0 ]]; then
      components_start_index=0
    fi
  done

  for ((i = 0; i < components_start_index; i++)); do
    components_array+=("${all_args[$i]}")
  done

  local collected_components=()

  if [[ "$filter_source_components" = "true" ]]; then
    local source_components_to_filter=("${components_array[@]}")
    local all_components_for_context=("${components_array[@]}")
    local filtered_source_components_str

    filtered_source_components_str="$(filter_removable_dependencies_with_context "${source_components_to_filter[@]}" "${all_components_for_context[@]}" "$skip_preset_checks" "$exclude_preset")" || {
      ui_error "Failed to filter source components for uninstallation."
      return 1
    }

    while IFS= read -r comp; do
      collected_components+=("$comp")
    done <<<"$filtered_source_components_str"
  else
    for component in "${components_array[@]}"; do
      collected_components+=("$component")
    done
  fi

  local previous_count=0
  local current_count=${#collected_components[@]}

  while [[ "$current_count" -gt "$previous_count" ]]; do
    previous_count="$current_count"
    local new_dependencies_to_check=()

    for component in "${collected_components[@]}"; do
      local dependencies_str
      dependencies_str="$(get_component_dependencies "$component")" || {
        ui_warning "$(_f "Failed to get dependencies for '%s', some dependencies might be missed during recursive check." "$component")"
        continue
      }

      local dependencies=()
      while IFS= read -r dep; do
        dependencies+=("$dep")
      done <<<"$dependencies_str"

      for dep in "${dependencies[@]}"; do
        if [[ -n "$dep" ]] && is_component_installed "$dep"; then
          local already_added="false"
          for existing in "${new_dependencies_to_check[@]}"; do
            if [[ "$existing" = "$dep" ]]; then
              already_added="true"
              break
            fi
          done
          if [[ "$already_added" = "false" ]]; then
            for existing in "${collected_components[@]}"; do
              if [[ "$existing" = "$dep" ]]; then
                already_added="true"
                break
              fi
            done
          fi

          if [[ "$already_added" = "false" ]]; then
            new_dependencies_to_check+=("$dep")
          fi
        fi
      done
    done

    if [[ ${#new_dependencies_to_check[@]} -gt 0 ]]; then
      local all_components_to_remove=()
      for comp in "${collected_components[@]}"; do
        all_components_to_remove+=("$comp")
      done
      for comp in "${new_dependencies_to_check[@]}"; do
        all_components_to_remove+=("$comp")
      done

      local removable_dependencies_str
      removable_dependencies_str="$(filter_removable_dependencies_with_context "${new_dependencies_to_check[@]}" "${all_components_to_remove[@]}" "$skip_preset_checks" "$exclude_preset")" || {
        ui_error "Failed to filter removable dependencies during recursive check."
        return 1
      }

      local removable_dependencies=()
      while IFS= read -r dep; do
        removable_dependencies+=("$dep")
      done <<<"$removable_dependencies_str"

      for dep in "${removable_dependencies[@]}"; do
        local already_added="false"
        for existing in "${collected_components[@]}"; do
          if [[ "$existing" = "$dep" ]]; then
            already_added="true"
            break
          fi
        done
        if [[ "$already_added" = "false" ]]; then
          collected_components+=("$dep")
        fi
      done
    fi

    current_count=${#collected_components[@]}
  done

  local sorted_components_str
  sorted_components_str="$(topological_sort_for_installation "${collected_components[@]}")" || {
    ui_error "Failed to topologically sort components for uninstall."
    return 1
  }

  local sorted_components=()
  while IFS= read -r comp; do
    sorted_components+=("$comp")
  done <<<"$sorted_components_str"

  for ((i = ${#sorted_components[@]} - 1; i >= 0; i--)); do
    echo "${sorted_components[$i]}"
  done
}

uninstall_component() {
  local all_args=("$@")
  local requested_components=()
  local force_flag="false"
  local skip_preset_checks="false"
  local exclude_preset=""

  # Parse arguments left to right
  local i=0
  while [[ $i -lt ${#all_args[@]} ]]; do
    local current_arg="${all_args[$i]}"
    case "$current_arg" in
      "--force")
        force_flag="true"
        ;;
      "--skip-preset-checks")
        skip_preset_checks="true"
        ;;
      --exclude-preset=*)
        exclude_preset="${current_arg#--exclude-preset=}"
        ;;
      *)
        requested_components+=("$current_arg")
        ;;
    esac
    ((i++))
  done

  if [[ ${#requested_components[@]} -eq 0 ]]; then
    ui_error "No components specified for uninstallation."
    return 1
  fi

  local components=()
  for component in "${requested_components[@]}"; do
    if ! is_component_installed "$component"; then
      ui_warning "$(_f "Component '%s' is not installed, skipping uninstallation." "$component")"
      continue
    fi

    local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
    if [[ ! -f "$component_file" ]]; then
      ui_error "$(_f "Component definition file for '%s' not found at %s." "$component" "$component_file")"
      continue
    fi

    components+=("$component")
  done

  if [[ ${#components[@]} -eq 0 ]]; then
    ui_info "No components are installed that match the uninstall request."
    return 0
  fi

  if [[ "$force_flag" != "true" ]]; then
    for component in "${components[@]}"; do
      local dependent_components=()
      local dep_str
      dep_str="$(get_components_depending_on "$component")" || {
        ui_warning "$(_f "Failed to get components depending on '%s', potential dependency issues might occur." "$component")"
        continue
      }
      while IFS= read -r dep; do
        dependent_components+=("$dep")
      done <<<"$dep_str"

      local filtered_dependents=()
      for dep in "${dependent_components[@]}"; do
        if [[ -n "$dep" ]]; then
          local dep_is_being_uninstalled="false"
          for uninstall_comp in "${components[@]}"; do
            if [[ "$uninstall_comp" = "$dep" ]]; then
              dep_is_being_uninstalled="true"
              break
            fi
          done
          if [[ "$dep_is_being_uninstalled" = "false" ]]; then
            filtered_dependents+=("$dep")
          fi
        fi
      done

      if [[ ${#filtered_dependents[@]} -gt 0 ]]; then
        ui_error "$(_f "Cannot uninstall component '%s' because it is required by the following installed components:" "$component")"
        for dep_comp in "${filtered_dependents[@]}"; do
          ui_action_error "$(_f "  - %s" "$dep_comp")"
        done
        ui_error "Please uninstall the dependent components first, or use --force to override."
        return 1
      fi

      local dependent_presets=()
      local preset_str
      preset_str="$(get_presets_depending_on "$component" "$exclude_preset")" || {
        ui_warning "$(_f "Failed to get presets depending on '%s', preset dependency issues might occur." "$component")"
        continue
      }
      while IFS= read -r current_preset; do
        dependent_presets+=("$current_preset")
      done <<<"$preset_str"

      local filtered_presets=()
      for current_preset in "${dependent_presets[@]}"; do
        if [[ -n "$current_preset" ]]; then
          filtered_presets+=("$current_preset")
        fi
      done

      if [[ ${#filtered_presets[@]} -gt 0 && "$skip_preset_checks" = "false" ]]; then
        ui_error "$(_f "Cannot uninstall component '%s' because it is required by the following installed presets:" "$component")"
        for current_preset in "${filtered_presets[@]}"; do
          ui_action_error "$(_f "  - %s" "$current_preset")"
        done
        ui_error "Please uninstall the presets first, use a different preset configuration, or use --force to override."
        return 1
      fi
    done
  else
    ui_info "Force flag detected - skipping dependency checks."
  fi

  local collect_args=("${components[@]}")
  if [[ "$skip_preset_checks" = "true" ]]; then
    collect_args+=("--skip-preset-checks")
  fi
  if [[ -n "$exclude_preset" ]]; then
    collect_args+=("--exclude-preset=$exclude_preset")
  fi

  local multiple_uninstall_order_str
  multiple_uninstall_order_str="$(collect_multiple_components_for_uninstall "${collect_args[@]}")" || {
    ui_error "Failed to determine uninstallation order."
    return 1
  }

  local multiple_uninstall_order=()
  while IFS= read -r comp; do
    multiple_uninstall_order+=("$comp")
  done <<<"$multiple_uninstall_order_str"

  if [[ ${#multiple_uninstall_order[@]} -eq 0 ]]; then
    ui_info "No components to uninstall."
    return 0
  fi

  local component_count=${#components[@]}
  local plural_suffix=""
  if [[ "$component_count" -gt 1 ]]; then
    plural_suffix="s"
  fi
  ui_action_start "$(_f "Will uninstall %d component%s with dependencies" "$component_count" "$plural_suffix")"
  ui_indent "$(_f "Total components to uninstall: %d" "${#multiple_uninstall_order[@]}")"

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "Uninstall order:"
    for comp in "${multiple_uninstall_order[@]}"; do
      local is_requested_component="false"
      for requested_comp in "${requested_components[@]}"; do
        if [[ "$requested_comp" = "$comp" ]]; then
          is_requested_component="true"
          break
        fi
      done

      if [[ "$is_requested_component" = "true" ]]; then
        ui_verbose_info "$(_f "  ➤ %s (requested component)" "$comp")"
      else
        ui_verbose_info "$(_f "  ↪ %s (unused dependency)" "$comp")"
      fi
    done
  else
    local deps_list=""
    local requested_comp_list=""
    for comp in "${multiple_uninstall_order[@]}"; do
      local is_requested_component="false"
      for requested_comp in "${requested_components[@]}"; do
        if [[ "$requested_comp" = "$comp" ]]; then
          is_requested_component="true"
          break
        fi
      done

      if [[ "$is_requested_component" = "true" ]]; then
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
      ui_indent "$(_f "Requested components: %s" "$requested_comp_list")"
    fi
    if [[ -n "$deps_list" ]]; then
      ui_indent "$(_f "Unused dependencies: %s" "$deps_list")"
    fi
  fi

  if ! _initialize_session; then
    ui_error "Session initialization failed."
    return 1
  fi

  local overall_success="true"

  for component in "${multiple_uninstall_order[@]}"; do
    local is_requested_component="false"
    for requested_comp in "${requested_components[@]}"; do
      if [[ "$requested_comp" = "$component" ]]; then
        is_requested_component="true"
        break
      fi
    done

    if ! _uninstall_single_component "$component" "$is_requested_component"; then
      ui_warning "$(_f "Failed to uninstall component: %s." "$component")"
      overall_success="false"
    fi
  done

  _finalize_session

  if [[ "$overall_success" = "true" ]]; then
    ui_action_success "$(_f "Component%s uninstalled successfully." "$plural_suffix")"
    return 0
  else
    ui_warning "$(_f "Component%s uninstalled with some warnings/errors." "$plural_suffix")"
    return 1
  fi
}

_uninstall_single_component() {
  local component="$1"
  local is_requested_component="${2:-true}"
  local skip_packages="${3:-false}"

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_component_uninstalling "$component"
  else
    if [[ "$is_requested_component" = "true" ]]; then
      ui_component_uninstalling "$component"
    else
      ui_dependency "$(_f "Removing unused dependency: %s" "$component")"
    fi
  fi

  local success="true"

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Removing symlinks and restoring backups for %s" "$component")"
  fi
  if remove_component_symlinks "$component"; then
    ui_verbose_action_success "Symlinks removed and backups restored successfully."
  else
    ui_warning "$(_f "Some symlink removal/backup restoration may have failed for %s." "$component")"
    success="false"
  fi

  cleanup_component "$component"

  if has_component_repository_config "$component"; then
    if [[ "$MEOW_VERBOSE" = "true" ]]; then
      ui_step_header "$(_f "Cleaning up repository for %s" "$component")"
    fi
    if cleanup_component_repository "$component"; then
      ui_verbose_action_success "Repository cleaned successfully."
    else
      ui_warning "$(_f "Repository cleanup failed for %s." "$component")"
      success="false"
    fi
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Uninstalling packages for %s" "$component")"
  fi
  if [[ "$skip_packages" = "true" ]]; then
    ui_verbose_info "$(_f "Skipping package removal for %s (requested)." "$component")"
  else
    if uninstall_component_packages "$component"; then
      ui_verbose_action_success "Packages uninstalled successfully."
    else
      ui_warning "$(_f "Some package uninstallation may have failed for %s." "$component")"
      success="false"
    fi
  fi

  cleanup_component_sources "$component"

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Removing component tracking for %s" "$component")"
  fi
  remove_component_symlink "$component"
  ui_verbose_action_success "Component tracking removed."

  if [[ "$success" = "true" ]]; then
    _icon_msg_core "${RED}✓ " "$(_f "Component uninstalled: %s" "$component")"
    return 0
  else
    _icon_msg_core "${RED}✗ " "$(_f "Failed to fully uninstall component: %s" "$component")"
    return 1
  fi
}
