#!/usr/bin/env bash

# lib/commands/update.sh - Command library for updating dotfiles

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_COMMANDS_UPDATE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_UPDATE_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/package/presets.sh"
source "${DOTFILES_DIR}/lib/package/homebrew.sh"
source "${DOTFILES_DIR}/lib/package/npm.sh"
source "${DOTFILES_DIR}/lib/package/go.sh"

declare -g UPDATED_PRESETS=""

_initialize_update_session() {
  setup_homebrew
  UPDATED_PRESETS=""
}

_finalize_update_session() {
    cleanup_homebrew
}

_check_preset_already_updated() {
  local preset="$1"
  local indent_level="$2"

  if [[ "$UPDATED_PRESETS" == *"|$preset|"* ]]; then
    info_italic_msg "$indent_level" "Preset '$preset' already updated, skipping"
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

  if command -v yq &>/dev/null; then
    return 0
  fi

  indented_warning "$indent_level" "yq is required, attempting to install"

  if ! command -v brew &>/dev/null; then
    indented_error_msg "$indent_level" "Homebrew not found, cannot install yq automatically"
    return 1
  fi

  if brew install yq >/dev/null 2>&1; then
    success_tick_msg "$indent_level" "yq installed successfully via Homebrew"
  else
    indented_error_msg "$indent_level" "Failed to install yq via Homebrew"
    return 1
  fi
}

_parse_preset_dependencies() {
  local preset_file="$1"
  local dependencies_var="$2"

  local dependencies_str
  dependencies_str=$(yq eval '.depends_on[]' "$preset_file" 2>/dev/null)

  if [[ -z "$dependencies_str" || "$dependencies_str" == "null" ]]; then
    return 0
  fi

  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      eval "${dependencies_var}+=(\"$line\")"
    fi
  done <<< "$dependencies_str"
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

update_preset_with_dependencies() {
  local preset="$1"
  local indent_level="${2:-0}"
  local preset_file="${DOTFILES_DIR}/presets/${preset}.yaml"
  local child_indent=$((indent_level + 1))

  _check_preset_already_updated "$preset" "$indent_level" && return 0
  _validate_preset_file "$preset_file" "$indent_level" || return 1
  _ensure_yq_available "$child_indent" || return 1

  step_header "$indent_level" "Updating preset: $preset"

  _update_preset_dependencies "$preset" "$preset_file" "$child_indent"
  update_preset_packages "$preset" "$child_indent"

  # Execute custom script if specified (for updates)
  local script_name
  script_name=$(yq eval '.script?' "$preset_file" 2>/dev/null)
  if [[ -n "$script_name" && "$script_name" != "null" ]]; then
    source "${DOTFILES_DIR}/lib/package/presets.sh" # Ensure execute_preset_script is available
    execute_preset_script "$script_name" "$preset" "$child_indent"
  fi

  UPDATED_PRESETS="${UPDATED_PRESETS}|$preset|"
  success_tick_msg "$indent_level" "Preset '$preset' updated successfully"
}

update_preset_packages() {
  local preset="$1"
  local indent_level="${2:-1}"

  _update_homebrew_packages "$preset" "$indent_level" || return 1
  _update_pipx_packages "$preset" "$indent_level" || return 1
  _update_mas_packages "$preset" "$indent_level" || return 1
  _update_npm_packages "$preset" "$indent_level" || return 1
  _update_go_packages "$preset" "$indent_level" || return 1
  _update_vscode_extensions "$preset" "$indent_level" || return 1
}

_update_package_type() {
  local preset="$1"
  local indent_level="$2"
  local package_type="$3"
  local command_name="$4"
  local file_extension="$5"
  local update_function="$6"

  # Map package types to their actual directory variable names
  local package_dir_var
  case "$package_type" in
    "homebrew") package_dir_var="BREW_PACKAGES_DIR" ;;
    "vscode") package_dir_var="VSCODE_PACKAGES_DIR" ;;
    "mas") package_dir_var="MAS_PACKAGES_DIR" ;;
    "pipx") package_dir_var="PIPX_PACKAGES_DIR" ;;
    *)
      local upper_package_type
      upper_package_type=$(echo "$package_type" | tr '[:lower:]' '[:upper:]')
      package_dir_var="${upper_package_type}_PACKAGES_DIR"
      ;;
  esac

  local package_dir
  eval "package_dir=\$$package_dir_var"
  local package_file="${package_dir}/${preset}.${file_extension}"

  if ! command -v "$command_name" &>/dev/null || [[ ! -f "$package_file" ]]; then
    return 0
  fi

  local capitalized_type
  capitalized_type=$(echo "$package_type" | sed 's/^./\U&/')

  if "$update_function" "$preset" "$indent_level"; then
    success_tick_msg "$indent_level" "${capitalized_type} packages for '$preset' updated successfully"
  else
    indented_error_msg "$indent_level" "Failed to update ${package_type} packages for '$preset'"
    return 1
  fi
}

_update_homebrew_packages() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "homebrew" "brew" "Brewfile" "update_brew_packages"
}

_update_pipx_packages() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "pipx" "pipx" "Pipxfile" "update_pipx_packages"
}

_update_mas_packages() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "mas" "mas" "Masfile" "update_mas_packages"
}

_update_npm_packages() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "npm" "npm" "npmfile" "update_npm_packages"
}

_update_go_packages() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "go" "go" "Gofile" "update_go_packages"
}

_update_vscode_extensions() {
  local preset="$1"
  local indent_level="$2"

  _update_package_type "$preset" "$indent_level" "vscode" "code" "Vscodefile" "update_vscode_extensions"
}

_process_presets() {
  local installed_presets="$1"
  local indent="$2"
  local preset_count_var="$3"
  local successful_updates_var="$4"
  local failed_updates_var="$5"

  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue

    # Skip the "all" preset as it's a meta-preset that installs other presets
    if [[ "$preset" == "all" ]]; then
      info_italic_msg $((indent + 1)) "Skipping 'all' preset (meta-preset)"
      continue
    fi

    eval "$preset_count_var=\$((\$$preset_count_var + 1))"

    if update_preset_with_dependencies "$preset" $((indent + 1)); then
      eval "$successful_updates_var=\$((\$$successful_updates_var + 1))"
    else
      eval "$failed_updates_var=\$((\$$failed_updates_var + 1))"
    fi
  done <<< "$installed_presets"
}

_validate_installed_presets() {
  local installed_presets="$1"
  local indent_level="$2"

  if [[ -z "$installed_presets" ]]; then
    indented_warning "$indent_level" "No presets found in installed presets list"
    info "$indent_level" "Use './bin/install.sh PRESET_NAME' to install presets first"
    info "$indent_level" "Available presets can be found in the 'presets/' directory"
    return 1
  fi
  return 0
}

_report_update_results() {
  local indent="$1"
  local preset_count="$2"
  local successful_updates="$3"
  local failed_updates="$4"

  if [[ $preset_count -eq 0 ]]; then
    indented_warning "$indent" "No installed presets found to update"
    return 1
  elif [[ $failed_updates -eq 0 ]]; then
    success_tick_msg "$indent" "All $successful_updates installed presets updated successfully"
  else
    indented_warning "$indent" "Updated $successful_updates presets successfully, $failed_updates failed"
    return 1
  fi
}

update_installed_presets() {
  local indent=0

  UPDATED_PRESETS=""
  header "$indent" "Updating all installed presets"

  local installed_presets
  installed_presets=$(get_installed_presets)

  _validate_installed_presets "$installed_presets" $((indent + 1)) || return 1

  _initialize_update_session

  local preset_count=0
  local successful_updates=0
  local failed_updates=0

  _process_presets "$installed_presets" "$indent" preset_count successful_updates failed_updates

  _finalize_update_session
  _report_update_results "$indent" "$preset_count" "$successful_updates" "$failed_updates"
}

update_preset() {
  local preset="$1"

  header 0 "Updating preset: $preset"
  _initialize_update_session
  update_preset_with_dependencies "$preset" 0
  _finalize_update_session
}
