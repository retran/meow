#!/usr/bin/env bash

# lib/commands/update.sh - Command library for updating dotfiles

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_COMMANDS_UPDATE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_UPDATE_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/presets.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"

UPDATED_PRESETS=""

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

  if command -v yq >/dev/null 2>&1; then
    return 0
  fi

  indented_warning "$indent_level" "yq is required, attempting to install"

  if ! command -v brew >/dev/null 2>&1; then
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

update_preset_with_dependencies() {
  local preset="$1"
  local indent_level="${2:-0}"
  local preset_file="${MEOW}/presets/${preset}.yaml"
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
    source "${MEOW}/lib/package/symlinks.sh" # Ensure setup_symlinks is available
    local symlink_categories=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && symlink_categories+=("$line")
    done < <(printf '%s\n' "$symlink_categories_str")
    for category_name in "${symlink_categories[@]}"; do
      setup_symlinks "$category_name" "$child_indent"
    done
  fi

  local script_name
  script_name=$(yq eval '.script?' "$preset_file" 2>/dev/null)
  if [[ -n "$script_name" && "$script_name" != "null" ]]; then
    source "${MEOW}/lib/package/presets.sh"
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

  local homebrew_status pipx_status mas_status npm_status go_status cargo_status vscode_status

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

  _update_cargo_packages "$preset" "$indent_level"
  cargo_status=$?
  if [[ $cargo_status -eq 0 ]]; then
    had_updates=true
  elif [[ $cargo_status -eq 1 ]]; then
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


_update_homebrew_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v brew >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "Homebrew not available, skipping homebrew package updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local brew_categories_str
  brew_categories_str=$(yq eval '.homebrew.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$brew_categories_str" || "$brew_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_brew_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$brew_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_pipx_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v pipx >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "Pipx not available, skipping pipx package updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local pipx_categories_str
  pipx_categories_str=$(yq eval '.pipx.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$pipx_categories_str" || "$pipx_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_pipx_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$pipx_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_mas_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v mas >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "MAS not available, skipping mas package updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local mas_categories_str
  mas_categories_str=$(yq eval '.mas.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$mas_categories_str" || "$mas_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_mas_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$mas_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_npm_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v npm >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "NPM not available, skipping npm package updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local npm_categories_str
  npm_categories_str=$(yq eval '.npm.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$npm_categories_str" || "$npm_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_npm_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$npm_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_go_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v go >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "Go not available, skipping go package updates for '$preset'"
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
  done < <(printf '%s\n' "$go_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
    return 100
  fi
}

_update_cargo_packages() {
  local preset="$1"
  local indent_level="$2"
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v cargo >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "Cargo not available, skipping cargo package updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local cargo_categories_str
  cargo_categories_str=$(yq eval '.cargo.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$cargo_categories_str" || "$cargo_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_cargo_packages "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$cargo_categories_str")

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
  local preset_file="${MEOW}/presets/${preset}.yaml"
  local had_updates=false
  local had_errors=false

  if ! command -v code >/dev/null 2>&1; then
    info_italic_msg "$indent_level" "VSCode not available, skipping vscode extension updates for '$preset'"
    return 100
  fi

  _ensure_yq_available "$indent_level" || return 1

  local vscode_categories_str
  vscode_categories_str=$(yq eval '.vscode.packages[]?' "$preset_file" 2>/dev/null)

  if [[ -z "$vscode_categories_str" || "$vscode_categories_str" == "null" ]]; then
    return 100
  fi

  while IFS= read -r category; do
    local update_status
    update_vscode_extensions "$category" "$indent_level"
    update_status=$?

    if [[ $update_status -eq 0 ]]; then
      had_updates=true
    elif [[ $update_status -eq 1 ]]; then
      had_errors=true
    fi
  done < <(printf '%s\n' "$vscode_categories_str")

  if [[ $had_errors == true ]]; then
    return 1
  elif [[ $had_updates == true ]]; then
    return 0
  else
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
  done < <(printf '%s\n' "$installed_presets")
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
