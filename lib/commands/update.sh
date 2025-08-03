#!/usr/bin/env bash

# lib/commands/update.sh - Command library for updating dotfiles

if [[ -n "${_LIB_COMMANDS_UPDATE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_UPDATE_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/presets.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/vscode.sh"

UPDATED_PRESETS=""

_initialize_update_session() {
  local indent=0
  step_header "$indent" "Initializing package manager for update"

  if [[ "$IS_ALPINE" == "true" ]]; then
    indented_info "$((indent + 1))" "Alpine Linux detected. Using apk."
    setup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    indented_info "$((indent + 1))" "Debian-based system detected. Using APT."
    setup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    indented_info "$((indent + 1))" "macOS detected. Using Homebrew."
    setup_homebrew "$((indent + 1))"
  fi
}

_finalize_update_session() {
  local indent=0

  if [[ "$IS_ALPINE" == "true" ]]; then
    cleanup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew "$((indent + 1))"
  fi
}

_check_preset_already_updated() {
  local preset="$1"
  local indent_level="$2"

  if [[ "$UPDATED_PRESETS" == *"|$preset|"* ]]; then
    info_italic_msg "$indent_level" "Preset '$preset' already updated in this session, skipping"
    return 0
  fi
  return 1
}

_validate_preset_file() {
  local preset_file="$1"
  local indent_level="$2"

  if [[ ! -f "$preset_file" ]]; then
    indented_error_msg "$indent_level" "Preset file not found: $preset_file"
    return 1
  fi
  return 0
}

_ensure_yq_available() {
  local indent_level="$1"

  if command -v yq >/dev/null 2>&1; then
    return 0
  fi

  indented_warning "$indent_level" "yq is required, attempting to install..."

  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    sudo apt-get install -y yq >/dev/null 2>&1 &&
      success_tick_msg "$indent_level" "yq installed via APT" ||
      {
        indented_error_msg "$indent_level" "Failed to install yq via APT"
        return 1
      }
  elif [[ "$IS_MACOS" == "true" ]]; then
    brew install yq >/dev/null 2>&1 &&
      success_tick_msg "$indent_level" "yq installed via Homebrew" ||
      {
        indented_error_msg "$indent_level" "Failed to install yq via Homebrew"
        return 1
      }
  else
    indented_error_msg "$indent_level" "Cannot install yq automatically on this OS"
    return 1
  fi
}

_parse_preset_dependencies() {
  local preset_file="$1"
  local dependencies_var="$2"

  local dependencies_str
  dependencies_str=$(yq eval '.depends_on[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$dependencies_str" || "$dependencies_str" == "null" ]]; then
    return 0
  fi

  while IFS= read -r line; do
    [[ -n "$line" ]] && eval "${dependencies_var}+=(\"$line\")"
  done < <(printf '%s\n' "$dependencies_str")
}

_update_preset_dependencies() {
  local preset="$1"
  local preset_file="$2"
  local indent_level="$3"

  local dependencies=()
  _parse_preset_dependencies "$preset_file" "dependencies"

  for dependency in "${dependencies[@]}"; do
    dependency_msg "$indent_level" "Updating dependency: $dependency (for $preset)"
    update_preset_with_dependencies "$dependency" "$indent_level"
  done
}

# Generic function to update packages for a given package manager
_update_package_manager() {
  local manager_name="$1"
  local cli_command="$2"
  local preset="$3"
  local indent_level="$4"

  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v "$cli_command" >/dev/null 2>&1; then
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local categories_str
  categories_str=$(yq eval ".${manager_name}.packages[]?" "$preset_file" 2>/dev/null)

  if [[ -z "$categories_str" || "$categories_str" == "null" ]]; then
    return 100
  fi

  local update_function_name="update_${manager_name}_packages"
  if ! declare -F "$update_function_name" >/dev/null; then
    indented_error_msg "$indent_level" "Update function ${update_function_name} not found."
    return 1
  fi

  while IFS= read -r category; do
    "$update_function_name" "$category" "$indent_level"
    local status=$?
    [[ $status -eq 1 ]] && had_errors=true
    [[ $status -eq 0 ]] && had_updates=true
  done < <(printf '%s\n' "$categories_str")

  if $had_errors; then
    return 1
  elif $had_updates; then
    return 0
  else
    return 100
  fi
}

update_preset_packages() {
  local preset="$1"
  local indent_level="${2:-1}"
  local had_updates=false
  local had_error=false

  # OS-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    _update_package_manager "homebrew" "brew" "$preset" "$indent_level"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true

    _update_package_manager "mas" "mas" "$preset" "$indent_level"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _update_package_manager "apt" "apt-get" "$preset" "$indent_level"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  if [[ "$IS_ALPINE" == "true" ]]; then
    _update_package_manager "apk" "apk" "$preset" "$indent_level"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  fi

  # Cross-platform
  for mgr in pipx npm go cargo vscode; do
    _update_package_manager "$mgr" "$mgr" "$preset" "$indent_level"
    [[ $? -eq 1 ]] && had_error=true
    [[ $? -eq 0 ]] && had_updates=true
  done

  if $had_error; then
    return 1
  elif $had_updates; then
    return 0
  else
    return 100
  fi
}

update_preset_with_dependencies() {
  local preset="$1"
  local indent_level="${2:-0}"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local child_indent=$((indent_level + 1))
  local had_updates=false

  # не обновляем дважды
  _check_preset_already_updated "$preset" "$indent_level" && return 100

  _validate_preset_file "$preset_file" "$indent_level" || return 1
  _ensure_yq_available "$child_indent" || return 1

  step_header "$indent_level" "Updating preset: $preset"

  _update_preset_dependencies "$preset" "$preset_file" "$child_indent"

  update_preset_packages "$preset" "$child_indent"
  local package_status=$?

  if [[ $package_status -eq 1 ]]; then
    return 1
  elif [[ $package_status -eq 0 ]]; then
    had_updates=true
  fi

  # symlinks
  local symlink_categories_str
  symlink_categories_str=$(yq eval '.symlinks[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$symlink_categories_str" && "$symlink_categories_str" != "null" ]]; then
    source "${MEOW}/lib/package/symlinks.sh"
    while IFS= read -r category_name; do
      setup_symlinks "$category_name" "$child_indent"
    done < <(printf '%s\n' "$symlink_categories_str")
  fi

  # post-script
  local script_name
  script_name=$(yq eval '.script?' "$preset_file" 2>/dev/null)
  [[ -n "$script_name" && "$script_name" != "null" ]] &&
    execute_preset_script "$script_name" "$preset" "$child_indent"

  UPDATED_PRESETS="${UPDATED_PRESETS}|$preset|"

  if $had_updates; then
    success_tick_msg "$indent_level" "Preset '$preset' updated successfully"
    return 0
  else
    success_tick_msg "$indent_level" "Preset '$preset' is up-to-date"
    return 100
  fi
}

_process_presets() {
  local installed_presets="$1"
  local indent="$2"
  local preset_count_var="$3"
  local successful_updates_var="$4"
  local failed_updates_var="$5"
  local uptodate_updates_var="$6"

  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue

    # пропускаем пресеты, уже обработанные в зависимостях
    if [[ "$UPDATED_PRESETS" == *"|$preset|"* ]]; then
      info_italic_msg "$indent" "Skipping preset '$preset' (already processed)"
      continue
    fi

    eval "$preset_count_var=\$((\$$preset_count_var + 1))"

    update_preset_with_dependencies "$preset" $((indent + 1))
    local update_status=$?

    if [[ $update_status -eq 0 ]]; then
      eval "$successful_updates_var=\$((\$$successful_updates_var + 1))"
    elif [[ $update_status -eq 100 ]]; then
      eval "$uptodate_updates_var=\$((\$$uptodate_updates_var + 1))"
    else
      eval "$failed_updates_var=\$((\$$failed_updates_var + 1))"
    fi
  done < <(printf '%s\n' "$installed_presets")
}

_validate_installed_presets() {
  local installed_presets="$1"
  local indent_level="$2"

  if [[ -z "$installed_presets" ]]; then
    indented_warning "$indent_level" "No presets found in installed presets list"
    info "$indent_level" "Use './bin/meow install PRESET_NAME' first"
    info "$indent_level" "Available presets: $(ls "${MEOW}/presets"/*.yaml | xargs -n1 basename | sed 's/\.yaml$//')"
    return 1
  fi
  return 0
}

_report_update_results() {
  local indent="$1"
  local preset_count="$2"
  local successful_updates="$3"
  local failed_updates="$4"
  local uptodate_updates="$5"

  if [[ $preset_count -eq 0 ]]; then
    indented_warning "$indent" "No installed presets to update"
    return 1
  elif [[ $failed_updates -eq 0 ]]; then
    if [[ $successful_updates -gt 0 ]]; then
      if [[ $uptodate_updates -gt 0 ]]; then
        success_tick_msg "$indent" "Processed $preset_count presets: $successful_updates updated, $uptodate_updates already up-to-date"
      else
        success_tick_msg "$indent" "All $successful_updates presets updated successfully"
      fi
    else
      success_tick_msg "$indent" "All $uptodate_updates presets already up-to-date"
    fi
  else
    indented_warning "$indent" "Processed $preset_count presets: $successful_updates updated, $uptodate_updates up-to-date, $failed_updates failed"
    return 1
  fi
}

update_installed_presets() {
  local indent=0

  UPDATED_PRESETS=""
  header "$indent" "Updating all installed presets"

  local installed_presets
  installed_presets="$(get_installed_presets)"

  _validate_installed_presets "$installed_presets" $((indent + 1)) || return 1

  _initialize_update_session

  local preset_count=0
  local successful_updates=0
  local failed_updates=0
  local uptodate_updates=0

  _process_presets "$installed_presets" "$indent" preset_count successful_updates failed_updates uptodate_updates

  _finalize_update_session
  _report_update_results "$indent" "$preset_count" "$successful_updates" "$failed_updates" "$uptodate_updates"
}

update_preset() {
  local preset="$1"
  header 0 "Updating preset: $preset"
  _initialize_update_session
  update_preset_with_dependencies "$preset" 0
  _finalize_update_session
}
