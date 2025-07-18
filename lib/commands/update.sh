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
  local had_updates=false

  _check_preset_already_updated "$preset" "$indent_level" && return 100
  _validate_preset_file "$preset_file" "$indent_level" || return 1
  _ensure_yq_available "$child_indent" || return 1

  step_header "$indent_level" "Updating preset: $preset"

  _update_preset_dependencies "$preset" "$preset_file" "$child_indent"

  local package_status
  update_preset_packages "$preset" "$child_indent"
  package_status=$?

  if [[ $package_status -eq 0 ]]; then
    had_updates=true
  elif [[ $package_status -eq 1 ]]; then
    return 1
  fi

  local symlink_categories_str
  symlink_categories_str=$(yq eval '.symlinks[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$symlink_categories_str" && "$symlink_categories_str" != "null" ]]; then
    source "${DOTFILES_DIR}/lib/package/symlinks.sh" # Ensure setup_symlinks is available
    local symlink_categories=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && symlink_categories+=("$line")
    done <<< "$symlink_categories_str"
    for category_name in "${symlink_categories[@]}"; do
      setup_symlinks "$category_name" "$child_indent"
    done
  fi

  local script_name
  script_name=$(yq eval '.script?' "$preset_file" 2>/dev/null)
  if [[ -n "$script_name" && "$script_name" != "null" ]]; then
    source "${DOTFILES_DIR}/lib/package/presets.sh"
    execute_preset_script "$script_name" "$preset" "$child_indent"
  fi

  UPDATED_PRESETS="${UPDATED_PRESETS}|$preset|"

  if [[ $had_updates == true ]]; then
    success_tick_msg "$indent_level" "Preset '$preset' updated successfully"
    return 0
  else
    success_tick_msg "$indent_level" "Preset '$preset' is up-to-date"
    return 100
  fi
}

update_preset_packages() {
  local preset="$1"
  local indent_level="${2:-1}"
  local had_updates=false
  local had_error=false

  local homebrew_status pipx_status mas_status npm_status go_status vscode_status

  _update_homebrew_packages "$preset" "$indent_level"
  homebrew_status=$?
  if [[ $homebrew_status -eq 0 ]]; then
    had_updates=true
  elif [[ $homebrew_status -eq 1 ]]; then
    had_error=true
  fi

  _update_pipx_packages "$preset" "$indent_level"
  pipx_status=$?
  if [[ $pipx_status -eq 0 ]]; then
    had_updates=true
  elif [[ $pipx_status -eq 1 ]]; then
    had_error=true
  fi

  _update_mas_packages "$preset" "$indent_level"
  mas_status=$?
  if [[ $mas_status -eq 0 ]]; then
    had_updates=true
  elif [[ $mas_status -eq 1 ]]; then
    had_error=true
  fi

  _update_npm_packages "$preset" "$indent_level"
  npm_status=$?
  if [[ $npm_status -eq 0 ]]; then
    had_updates=true
  elif [[ $npm_status -eq 1 ]]; then
    had_error=true
  fi

  _update_go_packages "$preset" "$indent_level"
  go_status=$?
  if [[ $go_status -eq 0 ]]; then
    had_updates=true
  elif [[ $go_status -eq 1 ]]; then
    had_error=true
  fi

  _update_vscode_extensions "$preset" "$indent_level"
  vscode_status=$?
  if [[ $vscode_status -eq 0 ]]; then
    had_updates=true
  elif [[ $vscode_status -eq 1 ]]; then
    had_error=true
  fi

  if [[ $had_error == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_package_type() {
  local preset="$1"
  local indent_level="$2"
  local package_type="$3"
  local command_name="$4"
  local file_extension="$5"
  local update_function="$6"

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
  local category="${preset#components/}"
  local package_file="${package_dir}/${category}.${file_extension}"

  if [[ ! -f "$package_file" ]]; then
    return 100
  fi

  if ! command -v "$command_name" &>/dev/null; then
    local capitalized_type
    capitalized_type=$(echo "$package_type" | sed 's/^./\U&/')
    info_italic_msg "$indent_level" "$capitalized_type not available, skipping $package_type package updates for '$category'"
    return 100
  fi

  local capitalized_type
  capitalized_type=$(echo "$package_type" | sed 's/^./\U&/')

  local update_status
  "$update_function" "$category" "$indent_level"
  update_status=$?

  if [[ $update_status -eq 0 ]]; then
    return 0
  elif [[ $update_status -eq 100 ]]; then
    return 100
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
  local preset_file="${DOTFILES_DIR}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v go &>/dev/null; then
    info_italic_msg "$indent_level" "Go not available, skipping go package updates for '${preset#components/}'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local go_categories_str
  go_categories_str=$(yq eval '.go.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$go_categories_str" || "$go_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_go_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done <<< "$go_categories_str"

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
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
  local uptodate_updates_var="$6"

  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue

    eval "$preset_count_var=\$((\$$preset_count_var + 1))"

    local update_status
    update_preset_with_dependencies "$preset" $((indent + 1))
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      eval "$successful_updates_var=\$((\$$successful_updates_var + 1))"
    elif [[ $update_status -eq 100 ]]; then
      eval "$uptodate_updates_var=\$((\$$uptodate_updates_var + 1))"
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
  local uptodate_updates="$5"

  if [[ $preset_count -eq 0 ]]; then
    indented_warning "$indent" "No installed presets found to update"
    return 1
  elif [[ $failed_updates -eq 0 ]]; then
    if [[ $successful_updates -gt 0 ]]; then
      if [[ $uptodate_updates -gt 0 ]]; then
        success_tick_msg "$indent" "Processed $preset_count installed presets: $successful_updates updated, $uptodate_updates already up-to-date"
      else
        success_tick_msg "$indent" "All $successful_updates installed presets updated successfully"
      fi
    else
      success_tick_msg "$indent" "All $uptodate_updates installed presets are already up-to-date"
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
  installed_presets=$(get_installed_presets)

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
