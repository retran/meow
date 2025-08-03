#!/usr/bin/env bash

# lib/package/presets.sh - Preset management for dotfiles

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_PRESETS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PRESETS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/pipx.sh"
source "${MEOW}/lib/package/mas.sh"
source "${MEOW}/lib/package/vscode.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/symlinks.sh"
source "${MEOW}/lib/system/macos.sh"

readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_INSTALLED_PRESETS_FILE="$HOME/.meow_installed_presets"
APPLIED_PRESETS=()

is_preset_applied() {
  local preset="$1"
  for applied in "${APPLIED_PRESETS[@]}"; do
    if [[ "$applied" == "$preset" ]]; then
      return 0
    fi
  done
  return 1
}

mark_preset_applied() {
  local preset="$1"
  APPLIED_PRESETS+=("$preset")
  debug "Marked preset '$preset' as applied"
  save_installed_preset "$preset"
}

save_installed_preset() {
  local preset="$1"
  touch "$MEOW_INSTALLED_PRESETS_FILE"
  if ! grep -Fxq "$preset" "$MEOW_INSTALLED_PRESETS_FILE" 2>/dev/null; then
    echo "$preset" >>"$MEOW_INSTALLED_PRESETS_FILE"
    debug "Saved preset '$preset' to installed presets file"
  fi
}

get_installed_presets() {
  if [[ -f "$MEOW_INSTALLED_PRESETS_FILE" ]]; then
    cat "$MEOW_INSTALLED_PRESETS_FILE" | sort | uniq
  fi
}

is_preset_installed() {
  local preset="$1"
  if [[ -f "$MEOW_INSTALLED_PRESETS_FILE" ]]; then
    grep -Fxq "$preset" "$MEOW_INSTALLED_PRESETS_FILE" 2>/dev/null
  else
    return 1
  fi
}

# Helper to install a tool if it's missing, using the correct package manager
_ensure_tool_available() {
  local tool="$1"
  local indent_level="$2"

  if command -v "$tool" >/dev/null 2>&1; then
    return 0
  fi

  indented_warning "$indent_level" "'$tool' is required. Attempting to install..."
  if [[ "$IS_MACOS" == "true" ]]; then
    if brew install "$tool" >/dev/null 2>&1; then
      success_tick_msg "$indent_level" "'$tool' installed successfully via Homebrew."
    else
      indented_error_msg "$indent_level" "Failed to install '$tool' via Homebrew."
      return 1
    fi
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    if sudo apt-get install -y "$tool" >/dev/null 2>&1; then
      success_tick_msg "$indent_level" "'$tool' installed successfully via APT."
    else
      indented_error_msg "$indent_level" "Failed to install '$tool' via APT."
      return 1
    fi
  else
    indented_error_msg "$indent_level" "Cannot install '$tool' automatically on this OS."
    return 1
  fi
}

# Generic helper to apply packages for a given manager
_apply_packages_for_manager() {
  local manager_name="$1"
  local preset_file="$2"
  local indent_level="$3"

  local install_function_name="install_${manager_name}_packages"
  if ! declare -F "$install_function_name" >/dev/null; then
    indented_error_msg "$indent_level" "Install function ${install_function_name} not found."
    return
  fi

  local categories_str
  categories_str=$(yq eval ".${manager_name}.packages[]?" "$preset_file" 2>/dev/null)

  if [[ -n "$categories_str" && "$categories_str" != "null" ]]; then
    while IFS= read -r category; do
      [[ -n "$category" ]] && "$install_function_name" "$category" "$indent_level"
    done < <(printf '%s\n' "$categories_str")
  fi
}

apply_preset() {
  local preset="$1"
  local skip_dependencies="${2:-false}"
  local parent_preset="${3:-}"
  local indent_level="${4:-0}"
  local preset_file="${MEOW_PRESETS_DIR}/${preset}.yaml"
  local current_indent="$indent_level"
  local child_indent=$((current_indent + 1))

  if [[ -n "$parent_preset" ]]; then
    dependency_msg "$current_indent" "Depends on: $preset (via $parent_preset)"
  fi

  step_header "$current_indent" "Applying preset: $preset"

  if [[ ! -f "$preset_file" ]]; then
    indented_error_msg "$child_indent" "Preset file not found: $preset_file"
    return 1
  fi

  if is_preset_applied "$preset"; then
    info_italic_msg "$child_indent" "Preset '$preset' already applied, skipping."
    return 0
  fi

  _ensure_tool_available "jq" "$child_indent" || return 1
  _ensure_tool_available "yq" "$child_indent" || return 1

  # Handle dependencies
  if [[ "$skip_dependencies" != "true" ]]; then
    local dependencies_str
    dependencies_str=$(yq eval '.depends_on[]' "$preset_file" 2>/dev/null)
    if [[ -n "$dependencies_str" && "$dependencies_str" != "null" ]]; then
      local dependencies=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && dependencies+=("$line")
      done < <(printf '%s\n' "$dependencies_str")
      for dependency in "${dependencies[@]}"; do
        if ! is_preset_applied "$dependency"; then
          apply_preset "$dependency" false "$preset" "$child_indent"
        fi
      done
    fi
  fi

  # Apply packages using the generic helper
  if [[ "$IS_MACOS" == "true" ]]; then
    _apply_packages_for_manager "homebrew" "$preset_file" "$child_indent"
    _apply_packages_for_manager "mas" "$preset_file" "$child_indent"
  fi
  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _apply_packages_for_manager "apt" "$preset_file" "$child_indent"
  fi
  _apply_packages_for_manager "pipx" "$preset_file" "$child_indent"
  _apply_packages_for_manager "vscode" "$preset_file" "$child_indent"
  _apply_packages_for_manager "npm" "$preset_file" "$child_indent"
  _apply_packages_for_manager "go" "$preset_file" "$child_indent"
  _apply_packages_for_manager "cargo" "$preset_file" "$child_indent"

  # Handle symlinks
  local symlink_categories_str
  symlink_categories_str=$(yq eval '.symlinks[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$symlink_categories_str" && "$symlink_categories_str" != "null" ]]; then
    local symlink_categories=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && symlink_categories+=("$line")
    done < <(printf '%s\n' "$symlink_categories_str")
    for category_name in "${symlink_categories[@]}"; do
      setup_symlinks "$category_name" "$child_indent"
    done
  fi

  # Handle custom script
  local script_name
  script_name=$(yq eval '.script?' "$preset_file" 2>/dev/null)
  if [[ -n "$script_name" && "$script_name" != "null" ]]; then
    execute_preset_script "$script_name" "$preset" "$child_indent"
  fi

  mark_preset_applied "$preset"
  success_tick_msg "$child_indent" "Preset '$preset' applied successfully."
  return 0
}

install_preset() {
  apply_preset "$@"
}

list_presets() {
  info 0 "Available presets:"
  if [[ -d "$MEOW_PRESETS_DIR" ]]; then
    local count=0
    for file in "$MEOW_PRESETS_DIR"/*.yaml; do
      if [[ -f "$file" ]]; then
        local preset_name
        preset_name=$(basename "$file" .yaml)
        if [[ "$file" == "$MEOW_PRESETS_DIR/components/"* ]]; then
          continue
        fi
        list_item_msg 1 "- $preset_name"
        count=$((count + 1))
      fi
    done
    if [[ $count -eq 0 ]]; then
      indented_info 0 "(No presets found)"
    fi
  else
    indented_info 0 "(No presets directory found at $MEOW_PRESETS_DIR)"
  fi
  return 0
}

list_installed_presets() {
  info 0 "Installed presets:"
  local installed_presets
  installed_presets=$(get_installed_presets)

  if [[ -z "$installed_presets" ]]; then
    indented_info 1 "(No presets installed or tracking file not found)"
    return 0
  fi

  local count=0
  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue
    list_item_msg 1 "- $preset"
    ((count++))
  done < <(printf '%s\n' "$installed_presets")

  if [[ $count -eq 0 ]]; then
    indented_info 1 "(No presets found in tracking file)"
  else
    info 0 "Total: $count preset(s) installed"
  fi
  return 0
}

execute_preset_script() {
  local script_name="$1"
  local preset="$2"
  local indent_level="$3"
  local script_path="${MEOW}/scripts/${script_name}"

  step_header "$indent_level" "Executing custom script: $script_name"

  if [[ ! -f "$script_path" ]]; then
    indented_error_msg "$indent_level" "Script not found: $script_path"
    return 1
  fi

  if [[ ! -x "$script_path" ]]; then
    action_msg "$indent_level" "Making script executable..."
    if chmod +x "$script_path"; then
      success_tick_msg "$((indent_level + 1))" "Script made executable"
    else
      indented_error_msg "$indent_level" "Failed to make script executable: $script_path"
      return 1
    fi
  fi

  action_msg "$indent_level" "Running script for preset: $preset"
  if "$script_path" "$preset" "$MEOW" "$indent_level"; then
    success_tick_msg "$indent_level" "Script '$script_name' executed successfully"
  else
    indented_error_msg "$indent_level" "Script '$script_name' failed with exit code $?"
    return 1
  fi
}
