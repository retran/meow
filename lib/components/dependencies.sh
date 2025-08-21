#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_DEPENDENCIES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_DEPENDENCIES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"

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
