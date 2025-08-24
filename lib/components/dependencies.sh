#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_DEPENDENCIES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_DEPENDENCIES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/components/core.sh"

get_components_depending_on() {
  local target_component="$1"
  local components=()

  for component_symlink in "${MEOW_INSTALLED_COMPONENTS_DIR}"/*; do
    if [[ ! -L "$component_symlink" ]]; then
      continue
    fi

    local component_name
    component_name=$(basename "$component_symlink")

    local component_file="${component_symlink}/component.yaml"
    if [[ ! -f "$component_file" ]]; then
      continue
    fi

    local deps_raw
    if ! deps_raw=$(read_yaml_array "$component_file" ".depends_on[]?"); then
      continue
    fi

    while IFS= read -r dep; do
      if [[ -n "$dep" && "$dep" != "null" ]]; then
        dep="${dep#components/}"
        if [[ "$dep" = "$target_component" ]]; then
          components+=("$component_name")
          break
        fi
      fi
    done < <(printf '%s\n' "$deps_raw")
  done

  printf '%s\n' "${components[@]}"
}

get_presets_depending_on() {
  local target_component="$1"
  local exclude_preset="${2:-}"
  local presets=()

  for preset_symlink in "${MEOW_INSTALLED_PRESETS_DIR}"/*; do
    if [[ ! -L "$preset_symlink" ]]; then
      continue
    fi

    local preset_name
    preset_name=$(basename "$preset_symlink")

    if [[ "$preset_name" = "$exclude_preset" ]]; then
      continue
    fi

    local preset_file="${preset_symlink}/preset.yaml"
    if [[ ! -f "$preset_file" ]]; then
      continue
    fi

    local required_deps_raw
    if ! required_deps_raw=$(read_yaml_array "$preset_file" ".required[]?"); then
      continue
    fi

    local required_deps=()
    while IFS= read -r dep_item; do
      required_deps+=("$dep_item")
    done < <(printf '%s\n' "$required_deps_raw")

    local found_direct=false
    for dep in "${required_deps[@]}"; do
      if [[ -n "$dep" && "$dep" != "null" ]]; then
        if [[ "$dep" = "$target_component" ]]; then
          presets+=("$preset_name")
          found_direct=true
          break
        fi
      fi
    done

    if [[ "$found_direct" = "false" ]]; then
      for dep in "${required_deps[@]}"; do
        if [[ -n "$dep" && "$dep" != "null" ]]; then
          local component_deps=()
          local comp_deps_raw
          comp_deps_raw=$(get_component_dependencies "$dep")
          while IFS= read -r comp_dep_item; do
            component_deps+=("$comp_dep_item")
          done < <(printf '%s\n' "$comp_deps_raw")

          for comp_dep in "${component_deps[@]}"; do
            if [[ "$comp_dep" = "$target_component" ]]; then
              presets+=("$preset_name")
              found_direct=true
              break 2
            fi
          done
        fi
      done
    fi

    if [[ "$found_direct" = "true" ]]; then
      break
    fi
  done

  printf '%s\n' "${presets[@]}"
}

get_component_dependencies() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  if [[ ! -f "$component_file" ]]; then
    return 1
  fi

  local depends_on_raw
  if ! depends_on_raw=$(read_yaml_array "$component_file" ".depends_on[]?"); then
    return 0
  fi

  while IFS= read -r dep; do
    if [[ -n "$dep" && "$dep" != "null" ]]; then
      printf '%s\n' "${dep#components/}"
    fi
  done < <(printf '%s\n' "$depends_on_raw")

  return 0
}

collect_dependencies_recursively_for_installation_stdout() {
  local component="$1"
  local dependencies_raw
  dependencies_raw=$(get_component_dependencies "$component")

  local dependencies=()
  while IFS= read -r dep_item; do
    dependencies+=("$dep_item")
  done < <(printf '%s\n' "$dependencies_raw")

  for dep in "${dependencies[@]}"; do
    if [[ -n "$dep" ]]; then
      printf '%s\n' "$dep"
      collect_dependencies_recursively_for_installation_stdout "$dep"
    fi
  done
}

collect_all_dependencies_for_installation() {
  local component="$1"
  local _result_array_name="$2"

  local all_deps_raw_with_duplicates
  all_deps_raw_with_duplicates=$(collect_dependencies_recursively_for_installation_stdout "$component")

  local all_components_unsorted_and_unique=()
  all_components_unsorted_and_unique+=("$component")

  local unique_deps_raw
  unique_deps_raw=$(printf '%s\n' "$all_deps_raw_with_duplicates" | sort -u)

  while IFS= read -r dep_item; do
    if [[ -n "$dep_item" && "$dep_item" != "$component" ]]; then
      all_components_unsorted_and_unique+=("$dep_item")
    fi
  done < <(printf '%s\n' "$unique_deps_raw")

  local sorted_deps_raw
  sorted_deps_raw=$(topological_sort_for_installation_stdout "${all_components_unsorted_and_unique[@]}")

  eval "${_result_array_name}=()"
  while IFS= read -r item; do
    eval "${_result_array_name}+=(\"$item\")"
  done < <(printf '%s\n' "$sorted_deps_raw")
}

topological_sort_for_installation_stdout() {
  local remaining_components=("$@")
  local sorted_components=()

  while [[ ${#remaining_components[@]} -gt 0 ]]; do
    local found_installable=false
    local new_remaining=()

    for component in "${remaining_components[@]}"; do
      local all_deps_satisfied=true

      local component_deps=()
      local comp_deps_raw
      comp_deps_raw=$(get_component_dependencies "$component")
      while IFS= read -r dep_item; do
        component_deps+=("$dep_item")
      done < <(printf '%s\n' "$comp_deps_raw")

      for dep in "${component_deps[@]}"; do
        if [[ -n "$dep" ]]; then
          local dep_in_remaining=false
          for remaining_comp in "${remaining_components[@]}"; do
            if [[ "$remaining_comp" = "$dep" ]]; then
              dep_in_remaining=true
              break
            fi
          done

          if [[ "$dep_in_remaining" = "true" ]]; then
            all_deps_satisfied=false
            break
          fi
        fi
      done

      if [[ "$all_deps_satisfied" = "true" ]]; then
        sorted_components+=("$component")
        found_installable=true
      else
        new_remaining+=("$component")
      fi
    done

    remaining_components=("${new_remaining[@]}")

    if [[ "$found_installable" = "false" && ${#remaining_components[@]} -gt 0 ]]; then
      ui_warning "$(_f "Circular dependencies detected among: %s" "$(printf '%s ' "${remaining_components[@]}")")"
      sorted_components+=("${remaining_components[@]}")
      break
    fi
  done

  printf '%s\n' "${sorted_components[@]}"
}

filter_removable_dependencies_with_context() {
  local _deps_to_check_name="$1"
  local _all_removing_name="$2"
  local _removable_name="$3"
  local skip_preset_checks="${4:-false}"
  local exclude_preset="${5:-}"

  local -a candidates=()
  local -a all_removing=()

  eval "candidates=(\"\${${_deps_to_check_name}[@]}\")"
  eval "all_removing=(\"\${${_all_removing_name}[@]}\")"

  local changed=true

  while [[ "$changed" = "true" ]]; do
    changed=false
    local new_candidates=()

    for dep in "${candidates[@]}"; do
      local should_keep=true

      if [[ -n "$dep" ]]; then
        if is_component_manually_installed "$dep"; then
          should_keep=false
        fi

        if [[ "$should_keep" = "true" ]]; then
          local other_dependents_raw
          other_dependents_raw=$(get_components_depending_on "$dep")

          local other_dependents=()
          while IFS= read -r item; do
            other_dependents+=("$item")
          done < <(printf '%s\n' "$other_dependents_raw")

          for dependent in "${other_dependents[@]}"; do
            if [[ -n "$dependent" ]]; then
              local in_removal_list=false
              for removing_component in "${all_removing[@]}"; do
                if [[ "$dependent" = "$removing_component" ]]; then
                  in_removal_list=true
                  break
                fi
              done

              if [[ "$in_removal_list" = "false" ]]; then
                should_keep=false
                break
              fi
            fi
          done
        fi

        if [[ "$should_keep" = "true" && "$skip_preset_checks" = "false" ]]; then
          local preset_dependents_raw
          preset_dependents_raw=$(get_presets_depending_on "$dep" "$exclude_preset")

          local preset_dependents=()
          while IFS= read -r current_preset; do
            preset_dependents+=("$current_preset")
          done < <(printf '%s\n' "$preset_dependents_raw")

          for current_preset in "${preset_dependents[@]}"; do
            if [[ -n "$current_preset" ]]; then
              should_keep=false
              break
            fi
          done
        fi

        if [[ "$should_keep" = "true" ]]; then
          new_candidates+=("$dep")
        else
          changed=true
        fi
      fi
    done

    candidates=("${new_candidates[@]}")
  done

  eval "${_removable_name}=()"
  for item in "${candidates[@]}"; do
    eval "${_removable_name}+=(\"$item\")"
  done
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

  local other_dependents=()
  while IFS= read -r dep; do
    other_dependents+=("$dep")
  done < <(printf '%s\n' "$other_dependents_raw")

  if [[ ${#other_dependents[@]} -gt 0 ]]; then
    return 1
  fi

  local preset_dependents_raw
  preset_dependents_raw=$(get_presets_depending_on "$dep_component" "$exclude_preset")

  local preset_dependents=()
  while IFS= read -r current_preset; do
    preset_dependents+=("$current_preset")
  done < <(printf '%s\n' "$preset_dependents_raw")

  if [[ ${#preset_dependents[@]} -gt 0 ]]; then
    return 1
  fi

  return 0
}

collect_removable_dependencies_recursively() {
  local component="$1"
  local _result_array_name="$2"

  local current_result_array=()
  eval "current_result_array=(\"\${${_result_array_name}[@]}\")"

  local dependencies_raw
  dependencies_raw=$(get_component_dependencies "$component")

  local dependencies=()
  while IFS= read -r dep_item; do
    dependencies+=("$dep_item")
  done < <(printf '%s\n' "$dependencies_raw")

  for dep in "${dependencies[@]}"; do
    if [[ -n "$dep" ]] && should_remove_dependency "$dep"; then
      local already_added=false
      for existing in "${current_result_array[@]}"; do
        if [[ "$existing" = "$dep" ]]; then
          already_added=true
          break
        fi
      done

      if [[ "$already_added" = "false" ]]; then
        eval "${_result_array_name}+=(\"$dep\")"
        current_result_array+=("$dep")

        collect_removable_dependencies_recursively "$dep" "$_result_array_name"
      fi
    fi
  done
}
