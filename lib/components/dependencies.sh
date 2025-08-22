#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_DEPENDENCIES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_DEPENDENCIES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/strings/strings.sh"

# Import core component functions we depend on
source "${MEOW}/lib/components/core.sh"

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
  local target_component="$1"
  local exclude_preset="${2:-}"
  local presets=()

  for preset_symlink in "${MEOW_INSTALLED_PRESETS_DIR}"/*; do
    [[ -L "$preset_symlink" ]] || continue

    local preset_name
    preset_name=$(basename "$preset_symlink")

    [[ "$preset_name" == "$exclude_preset" ]] && continue

    local preset_file="${preset_symlink}/preset.yaml"
    [[ -f "$preset_file" ]] || continue

    local required_deps
    required_deps=$(read_yaml_array "$preset_file" ".required[]?")

    local found_direct=false
    while IFS= read -r dep; do
      [[ -n "$dep" && "$dep" != "null" ]] || continue
      if [[ "$dep" == "$target_component" ]]; then
        presets+=("$preset_name")
        found_direct=true
        break
      fi
    done < <(printf '%s\n' "$required_deps")

    if [[ "$found_direct" == "false" ]]; then
      while IFS= read -r dep; do
        [[ -n "$dep" && "$dep" != "null" ]] || continue

        local component_deps=()
        get_component_dependencies "$dep" component_deps

        for comp_dep in "${component_deps[@]}"; do
          if [[ "$comp_dep" == "$target_component" ]]; then
            presets+=("$preset_name")
            found_direct=true
            break 2
          fi
        done
      done < <(printf '%s\n' "$required_deps")
    fi

    [[ "$found_direct" == "true" ]] && break
  done

  printf '%s\n' "${presets[@]}"
}

get_component_dependencies() {
  local component="$1"
  local -n deps_array_ref="$2"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [[ -f "$component_file" ]] || return 1

  local depends_on
  depends_on=$(read_yaml_array "$component_file" ".depends_on[]?") || return 0

  deps_array_ref=()
  while IFS= read -r dep; do
    [[ -n "$dep" && "$dep" != "null" ]] || continue

    dep="${dep#components/}"

    deps_array_ref+=("$dep")
  done < <(printf '%s\n' "$depends_on")

  return 0
}

# Collect all dependencies starting from component in topological order for installation
collect_all_dependencies_for_installation() {
  local component="$1"
  local -n result_ref="$2"
  local all_components=()

  collect_dependencies_recursively_for_installation "$component" all_components

  all_components+=("$component")

  local sorted_deps=()
  topological_sort_for_installation all_components sorted_deps
  result_ref=("${sorted_deps[@]}")
}

# Recursively collect all dependencies of a component for installation
collect_dependencies_recursively_for_installation() {
  local component="$1"
  local -n all_deps_ref="$2"

  _collect_deps_rec() {
    local comp="$1"
    local dependencies=()

    get_component_dependencies "$comp" dependencies

    for dep in "${dependencies[@]}"; do
      if [[ -n "$dep" ]]; then
        local already_added=false
        for existing in "${all_deps_ref[@]}"; do
          if [[ "$existing" == "$dep" ]]; then
            already_added=true
            break
          fi
        done

        if [[ "$already_added" == "false" ]]; then
          all_deps_ref+=("$dep")
          _collect_deps_rec "$dep"
        fi
      fi
    done
  }

  _collect_deps_rec "$component"
}

# Topological sort for installation (dependencies before dependents)
topological_sort_for_installation() {
  local -n input_array_ref="$1"
  local -n sorted_array_ref="$2"
  local remaining=("${input_array_ref[@]}")

  sorted_array_ref=()

  while [[ ${#remaining[@]} -gt 0 ]]; do
    local found_installable=false
    local new_remaining=()

    for component in "${remaining[@]}"; do
      local all_deps_satisfied=true

      local component_deps=()
      get_component_dependencies "$component" component_deps

      for dep in "${component_deps[@]}"; do
        if [[ -n "$dep" ]]; then
          local dep_in_remaining=false
          for remaining_comp in "${remaining[@]}"; do
            if [[ "$remaining_comp" == "$dep" ]]; then
              dep_in_remaining=true
              break
            fi
          done

          if [[ "$dep_in_remaining" == "true" ]]; then
            all_deps_satisfied=false
            break
          fi
        fi
      done

      if [[ "$all_deps_satisfied" == "true" ]]; then
        sorted_array_ref+=("$component")
        found_installable=true
      else
        new_remaining+=("$component")
      fi
    done

    remaining=("${new_remaining[@]}")

    if [[ "$found_installable" == "false" && ${#remaining[@]} -gt 0 ]]; then
      ui_warning "$(format_template_message "circular_dependencies_detected" "${remaining[*]}")"
      sorted_array_ref+=("${remaining[@]}")
      break
    fi
  done
}

# Filter dependencies with context of all components being removed
filter_removable_dependencies_with_context() {
  local -n deps_to_check_ref="$1"
  local -n all_removing_ref="$2"
  local -n removable_ref="$3"
  local skip_preset_checks="${4:-false}"
  local exclude_preset="${5:-}"
  local candidates=("${deps_to_check_ref[@]}")
  local changed=true

  while [[ "$changed" == "true" ]]; do
    changed=false
    local new_candidates=()

    for dep in "${candidates[@]}"; do
      local dep_copy="$dep"
      local should_keep=true

      if [[ -n "$dep_copy" ]]; then
        if is_component_manually_installed "$dep_copy"; then
          should_keep=false
        fi

        if [[ "$should_keep" == "true" ]]; then
          local other_dependents
          mapfile -t other_dependents < <(get_components_depending_on "$dep_copy")

          for dependent in "${other_dependents[@]}"; do
            if [[ -n "$dependent" ]]; then
              local in_removal_list=false
              for removing_component in "${all_removing_ref[@]}"; do
                if [[ "$dependent" == "$removing_component" ]]; then
                  in_removal_list=true
                  break
                fi
              done

              if [[ "$in_removal_list" == "false" ]]; then
                should_keep=false
                break
              fi
            fi
          done
        fi

        if [[ "$should_keep" == "true" && "$skip_preset_checks" == "false" ]]; then
          local preset_dependents
          mapfile -t preset_dependents < <(get_presets_depending_on "$dep_copy" "$exclude_preset")

          for current_preset in "${preset_dependents[@]}"; do
            if [[ -n "$current_preset" ]]; then
              should_keep=false
              break
            fi
          done
        fi

        if [[ "$should_keep" == "true" ]]; then
          new_candidates+=("$dep_copy")
        else
          changed=true
        fi
      fi
    done

    candidates=("${new_candidates[@]}")
  done

  removable_ref=("${candidates[@]}")
}

# Check if a dependency component should be removed
should_remove_dependency() {
  local dep_component="$1"
  local exclude_preset="${2:-}"

  if ! is_component_installed "$dep_component"; then
    return 1
  fi

  if is_component_manually_installed "$dep_component"; then
    return 1
  fi

  local other_dependents
  mapfile -t other_dependents < <(get_components_depending_on "$dep_component")

  local filtered_dependents=()
  for dep in "${other_dependents[@]}"; do
    if [[ -n "$dep" ]]; then
      filtered_dependents+=("$dep")
    fi
  done
  if [[ ${#filtered_dependents[@]} -gt 0 ]]; then
    return 1
  fi

  local preset_dependents
  mapfile -t preset_dependents < <(get_presets_depending_on "$dep_component" "$exclude_preset")

  local filtered_presets=()
  for current_preset in "${preset_dependents[@]}"; do
    if [[ -n "$current_preset" ]]; then
      filtered_presets+=("$current_preset")
    fi
  done
  if [[ ${#filtered_presets[@]} -gt 0 ]]; then
    return 1
  fi

  return 0
}

# Collect all dependencies that can be safely removed recursively (fixed version)
collect_removable_dependencies_recursively() {
  local component="$1"
  local -n result_ref="$2"
  local dependencies=()

  get_component_dependencies "$component" dependencies

  for dep in "${dependencies[@]}"; do
    local dep_copy="$dep"
    if [[ -n "$dep_copy" ]] && should_remove_dependency "$dep_copy"; then
      local already_added=false
      for existing in "${result_ref[@]}"; do
        if [[ "$existing" == "$dep_copy" ]]; then
          already_added=true
          break
        fi
      done

      if [[ "$already_added" == "false" ]]; then
        result_ref+=("$dep_copy")
        collect_removable_dependencies_recursively "$dep_copy" result_ref
      fi
    fi
  done
}

# Collect all dependencies that can be safely removed recursively
collect_removable_dependencies_recursively() {
  local component="$1"
  local dependencies=()

  get_component_dependencies "$component" dependencies

  for dep in "${dependencies[@]}"; do
    if [[ -n "$dep" ]] && should_remove_dependency "$dep"; then
      echo "$dep"
      collect_removable_dependencies_recursively "$dep"
    fi
  done
}
