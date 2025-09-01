#!/usr/bin/env bash

if [ -n "${_LIB_COMPONENTS_DEPENDENCIES_SOURCED:-}" ]; then
  return 0
fi
_LIB_COMPONENTS_DEPENDENCIES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/components/core.sh"

get_components_depending_on() {
  local target_component="$1"
  local components=""

  for component_symlink in "${MEOW_INSTALLED_COMPONENTS_DIR}"/*; do
    if [ ! -L "$component_symlink" ]; then
      continue
    fi

    local component_name
    component_name=$(basename "$component_symlink")

    local component_file="${component_symlink}/component.yaml"
    if [ ! -f "$component_file" ]; then
      continue
    fi

    local deps_raw
    if ! deps_raw=$(read_yaml_array "$component_file" ".depends_on[]?"); then
      continue
    fi

    local dep
    while IFS= read -r dep; do
      if [ -n "$dep" ] && [ "$dep" != "null" ]; then
        dep="${dep#components/}"
        if [ "$dep" = "$target_component" ]; then
          components="$components$component_name"$'\n'
          return 0
        fi
      fi
    done <<<"$deps_raw"
  done

  printf '%s\n' "$components"
}

get_presets_depending_on() {
  local target_component="$1"
  local exclude_preset="${2:-}"
  local presets=""

  for preset_symlink in "${MEOW_INSTALLED_PRESETS_DIR}"/*; do
    if [ ! -L "$preset_symlink" ]; then
      continue
    fi

    local preset_name
    preset_name=$(basename "$preset_symlink")

    if [ "$preset_name" = "$exclude_preset" ]; then
      continue
    fi

    local preset_file="${preset_symlink}/preset.yaml"
    if [ ! -f "$preset_file" ]; then
      continue
    fi

    local required_deps_raw
    if ! required_deps_raw=$(read_yaml_array "$preset_file" ".required[]?"); then
      continue
    fi

    local required_deps=""
    local dep_item
    while IFS= read -r dep_item; do
      if [ -n "$dep_item" ] && [ "$dep_item" != "null" ]; then
        required_deps="$required_deps$dep_item"$'\n'
      fi
    done <<<"$required_deps_raw"

    local found_direct=false
    local dep
    while IFS= read -r dep; do
      if [ -n "$dep" ] && [ "$dep" != "null" ]; then
        if [ "$dep" = "$target_component" ]; then
          presets="$presets$preset_name"$'\n'
          found_direct=true
          break
        fi
      fi
    done <<<"$required_deps"

    if [ "$found_direct" = "false" ]; then
      local dep
      while IFS= read -r dep; do
        if [ -n "$dep" ] && [ "$dep" != "null" ]; then
          local component_deps=""
          local comp_deps_raw
          comp_deps_raw=$(get_component_dependencies "$dep")
          local comp_dep_item
          while IFS= read -r comp_dep_item; do
            if [ -n "$comp_dep_item" ] && [ "$comp_dep_item" != "null" ]; then
              component_deps="$component_deps$comp_dep_item"$'\n'
            fi
          done <<<"$comp_deps_raw"

          local comp_dep
          while IFS= read -r comp_dep; do
            if [ "$comp_dep" = "$target_component" ]; then
              presets="$presets$preset_name"$'\n'
              found_direct=true
              break 2
            fi
          done <<<"$component_deps"
        fi
      done <<<"$required_deps"
    fi

    if [ "$found_direct" = "true" ]; then
      break
    fi
  done

  printf '%s\n' "$presets"
}

get_component_dependencies() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: get_component_dependencies called for component '%s'" "$component")" >&2
    ui_verbose_info "$(_f "Debug: Component file path: '%s'" "$component_file")" >&2
  fi

  if [ ! -f "$component_file" ]; then
    ui_error "$(_f "Component file not found: %s" "$component_file")"
    return 1
  fi

  # Check if the component has dependencies at all
  if ! yaml_path_exists "$component_file" ".depends_on"; then
    # No dependencies section - this is normal, not an error
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "Debug: Component '%s' has no dependencies section" "$component")" >&2
    fi
    return 0
  fi

  local depends_on_raw
  if ! depends_on_raw=$(read_yaml_array "$component_file" ".depends_on[]?"); then
    ui_warning "$(_f "Failed to read dependencies for component %s" "$component")"
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Raw dependencies for '%s': '%s'" "$component" "$depends_on_raw")" >&2
  fi

  local dep
  local result_deps=""
  while IFS= read -r dep; do
    if [ -n "$dep" ] && [ "$dep" != "null" ]; then
      local clean_dep="${dep#components/}"
      result_deps="$result_deps$clean_dep"$'\n'
      printf '%s\n' "$clean_dep"
    fi
  done <<<"$depends_on_raw"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Processed dependencies for '%s': '%s'" "$component" "$result_deps")" >&2
  fi

  return 0
}

collect_dependencies_recursively_for_installation_stdout() {
  local component="$1"
  local dependencies_raw
  dependencies_raw=$(get_component_dependencies "$component")

  local dependencies=""
  local dep_item
  while IFS= read -r dep_item; do
    if [ -n "$dep_item" ]; then
      dependencies="$dependencies$dep_item"$'\n'
    fi
  done <<<"$dependencies_raw"

  local dep
  while IFS= read -r dep; do
    if [ -n "$dep" ]; then
      printf '%s\n' "$dep"
      collect_dependencies_recursively_for_installation_stdout "$dep"
    fi
  done <<<"$dependencies"
}

topological_sort_for_installation() {
  local remaining_components=""
  for arg in "$@"; do
    remaining_components="$remaining_components$arg"$'\n'
  done

  local sorted_components=""
  local new_remaining=""

  while [ -n "$remaining_components" ]; do
    local found_installable=false
    new_remaining=""

    local component
    while IFS= read -r component; do
      if [ -z "$component" ]; then
        continue
      fi

      local all_deps_satisfied=true
      local component_deps_raw
      component_deps_raw=$(get_component_dependencies "$component")

      if [ -n "$component_deps_raw" ]; then
        local component_deps=""
        local dep_item
        while IFS= read -r dep_item; do
          if [ -n "$dep_item" ]; then
            component_deps="$component_deps$dep_item"$'\n'
          fi
        done <<<"$component_deps_raw"

        local dep
        while IFS= read -r dep; do
          if [ -n "$dep" ]; then
            local dep_in_remaining=false
            local remaining_comp
            while IFS= read -r remaining_comp; do
              if [ "$remaining_comp" = "$dep" ]; then
                dep_in_remaining=true
                break
              fi
            done <<<"$remaining_components"

            if [ "$dep_in_remaining" = "true" ]; then
              all_deps_satisfied=false
              break
            fi
          fi
        done <<<"$component_deps"
      fi

      if [ "$all_deps_satisfied" = "true" ]; then
        sorted_components="$sorted_components$component"$'\n'
        found_installable=true
      else
        new_remaining="$new_remaining$component"$'\n'
      fi
    done <<<"$remaining_components"

    remaining_components="$new_remaining"

    if [ "$found_installable" = "false" ] && [ -n "$remaining_components" ]; then
      ui_warning "$(_f "Circular dependencies detected among: %s" "$(printf '%s ' "$remaining_components")")"
      sorted_components="$sorted_components$remaining_components"
      break
    fi
  done

  printf '%s\n' "$sorted_components"
}

collect_all_dependencies_for_installation() {
  local component="$1"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: collect_all_dependencies_for_installation called for component '%s'" "$component")" >&2
  fi

  local all_deps_raw_with_duplicates
  all_deps_raw_with_duplicates=$(collect_dependencies_recursively_for_installation_stdout "$component")

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Raw dependencies for '%s': '%s'" "$component" "$all_deps_raw_with_duplicates")" >&2
  fi

  local all_components_unsorted_and_unique="$component"$'\n'

  local unique_deps_raw
  unique_deps_raw=$(printf '%s\n' "$all_deps_raw_with_duplicates" | sort -u)

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Unique dependencies for '%s': '%s'" "$component" "$unique_deps_raw")" >&2
  fi

  local dep_item
  while IFS= read -r dep_item; do
    if [ -n "$dep_item" ] && [ "$dep_item" != "$component" ]; then
      all_components_unsorted_and_unique="$all_components_unsorted_and_unique$dep_item"$'\n'
    fi
  done <<<"$unique_deps_raw"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: All components (unsorted/unique) for '%s': '%s'" "$component" "$all_components_unsorted_and_unique")" >&2
  fi

  local sorted_deps_raw
  sorted_deps_raw=$(topological_sort_for_installation "$(printf '%s\n' "$all_components_unsorted_and_unique")")

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Topologically sorted dependencies for '%s': '%s'" "$component" "$sorted_deps_raw")" >&2
  fi

  local result=""
  local item
  while IFS= read -r item; do
    if [ -n "$item" ]; then
      result="$result$item"$'\n'
    fi
  done <<<"$sorted_deps_raw"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_verbose_info "$(_f "Debug: Final result for '%s': '%s'" "$component" "$result")" >&2
  fi

  printf '%s\n' "$result"
}

filter_removable_dependencies_with_context() {
  local _deps_to_check_name="$1"
  local _all_removing_name="$2"
  local _removable_name="$3"
  local skip_preset_checks="${4:-false}"
  local exclude_preset="${5:-}"

  local candidates=""
  local all_removing=""

  eval "candidates=\"\${${_deps_to_check_name}[@]}\""
  eval "all_removing=\"\${${_all_removing_name}[@]}\""

  local changed=true

  while [ "$changed" = "true" ]; do
    changed=false
    local new_candidates=""

    local dep
    while IFS= read -r dep; do
      local should_keep=true

      if [ -n "$dep" ]; then
        if is_component_manually_installed "$dep"; then
          should_keep=false
        fi

        if [ "$should_keep" = "true" ]; then
          local other_dependents_raw
          other_dependents_raw=$(get_components_depending_on "$dep")

          local other_dependents=""
          local item
          while IFS= read -r item; do
            if [ -n "$item" ]; then
              other_dependents="$other_dependents$item"$'\n'
            fi
          done <<<"$other_dependents_raw"

          local dependent
          while IFS= read -r dependent; do
            if [ -n "$dependent" ]; then
              local in_removal_list=false
              local removing_component
              while IFS= read -r removing_component; do
                if [ "$dependent" = "$removing_component" ]; then
                  in_removal_list=true
                  break
                fi
              done <<<"$all_removing"

              if [ "$in_removal_list" = "false" ]; then
                should_keep=false
                break
              fi
            fi
          done <<<"$other_dependents"
        fi

        if [ "$should_keep" = "true" ] && [ "$skip_preset_checks" = "false" ]; then
          local preset_dependents_raw
          preset_dependents_raw=$(get_presets_depending_on "$dep" "$exclude_preset")

          local preset_dependents=""
          local current_preset
          while IFS= read -r current_preset; do
            if [ -n "$current_preset" ]; then
              preset_dependents="$preset_dependents$current_preset"$'\n'
            fi
          done <<<"$preset_dependents_raw"

          local current_preset
          while IFS= read -r current_preset; do
            if [ -n "$current_preset" ]; then
              should_keep=false
              break
            fi
          done <<<"$preset_dependents"
        fi

        if [ "$should_keep" = "true" ]; then
          new_candidates="$new_candidates$dep"$'\n'
        else
          changed=true
        fi
      fi
    done <<<"$candidates"

    candidates="$new_candidates"
  done

  eval "${_removable_name}=\"\""
  local item
  while IFS= read -r item; do
    if [ -n "$item" ]; then
      eval "${_removable_name}+=\"$item \""
    fi
  done <<<"$candidates"
}

should_remove_dependency() {
  local dep_component="$1"
  local exclude_preset="${2:-}"

  if ! is_component_installed "$dep_component"; then
    return 1
  fi

  if is_component_manually_installed "$dep_component"; then
    return 1
  fi

  local other_dependents_raw
  other_dependents_raw=$(get_components_depending_on "$dep_component")

  local other_dependents=""
  local dep
  while IFS= read -r dep; do
    if [ -n "$dep" ]; then
      other_dependents="$other_dependents$dep"$'\n'
    fi
  done <<<"$other_dependents_raw"

  if [ -n "$other_dependents" ]; then
    return 1
  fi

  local preset_dependents_raw
  preset_dependents_raw=$(get_presets_depending_on "$dep_component" "$exclude_preset")

  local preset_dependents=""
  local current_preset
  while IFS= read -r current_preset; do
    if [ -n "$current_preset" ]; then
      preset_dependents="$preset_dependents$current_preset"$'\n'
    fi
  done <<<"$preset_dependents_raw"

  if [ -n "$preset_dependents" ]; then
    return 1
  fi

  return 0
}

collect_removable_dependencies_recursively() {
  local component="$1"
  local _result_array_name="$2"

  local current_result_array=""
  eval "current_result_array=\"\${${_result_array_name}[@]}\""

  local dependencies_raw
  dependencies_raw=$(get_component_dependencies "$component")

  local dependencies=""
  local dep_item
  while IFS= read -r dep_item; do
    if [ -n "$dep_item" ]; then
      dependencies="$dependencies$dep_item"$'\n'
    fi
  done <<<"$dependencies_raw"

  local dep
  while IFS= read -r dep; do
    if [ -n "$dep" ] && should_remove_dependency "$dep"; then
      local already_added=false
      local existing
      while IFS= read -r existing; do
        if [ "$existing" = "$dep" ]; then
          already_added=true
          break
        fi
      done <<<"$current_result_array"

      if [ "$already_added" = "false" ]; then
        eval "${_result_array_name}+=\"$dep \""
        current_result_array="$current_result_array$dep"$'\n'

        collect_removable_dependencies_recursively "$dep" "$_result_array_name"
      fi
    fi
  done <<<"$dependencies"
}
