#!/usr/bin/env bash

# lib/package/presets.sh - Preset management system for dotfiles
#
# Manages installation and tracking of software presets, which are collections
# of packages and configurations that can be applied together. Supports multiple
# package managers including Homebrew, npm, pip, Go, Rust, and more.
#
# Key features:
# - Dependency resolution and recursive preset application
# - Multi-package-manager support (brew, npm, pip, go, cargo, etc.)
# - Installation tracking and state management
# - Symlink management for configuration files
# - JSON-based preset configuration

# Prevent multiple sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_PACKAGE_PRESETS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PRESETS_SOURCED=1

# Load required dependencies
source "${DOTFILES_DIR}/lib/core/ui.sh"
source "${DOTFILES_DIR}/lib/package/homebrew.sh"
source "${DOTFILES_DIR}/lib/package/pipx.sh"
source "${DOTFILES_DIR}/lib/package/mas.sh"
source "${DOTFILES_DIR}/lib/package/vscode.sh"
source "${DOTFILES_DIR}/lib/package/npm.sh"
source "${DOTFILES_DIR}/lib/package/go.sh"
source "${DOTFILES_DIR}/lib/package/cargo.sh"
source "${DOTFILES_DIR}/lib/package/symlinks.sh"
source "${DOTFILES_DIR}/lib/system/macos.sh"

#======================================
# Configuration and State Management
#======================================

# Directory containing preset configuration files
readonly PRESETS_DIR="${DOTFILES_DIR}/presets"

# File tracking which presets have been installed
readonly INSTALLED_PRESETS_FILE="$HOME/.installed_presets"

# Runtime array tracking presets applied in current session
APPLIED_PRESETS=()

#======================================
# Preset State Tracking Functions
#======================================

# Check if a preset has been applied in the current session
# Usage: is_preset_applied <preset_name>
# Returns: 0 if applied, 1 if not applied
is_preset_applied() {
  local preset="$1"
  
  for applied in "${APPLIED_PRESETS[@]}"; do
    if [[ "$applied" == "$preset" ]]; then
      return 0
    fi
  done
  return 1
}

# Mark a preset as applied in the current session and persist to disk
# Usage: mark_preset_applied <preset_name>
mark_preset_applied() {
  local preset="$1"
  
  APPLIED_PRESETS+=("$preset")
  debug "Marked preset '$preset' as applied"
  
  save_installed_preset "$preset"
}

# Persist preset installation to the tracking file
# Usage: save_installed_preset <preset_name>
save_installed_preset() {
  local preset="$1"

  # Ensure tracking file exists
  touch "$INSTALLED_PRESETS_FILE"

  # Add preset to tracking file if not already present
  if ! grep -Fxq "$preset" "$INSTALLED_PRESETS_FILE" 2>/dev/null; then
    echo "$preset" >> "$INSTALLED_PRESETS_FILE"
    debug "Saved preset '$preset' to installed presets file"
  fi
}

get_installed_presets() {
  if [[ -f "$INSTALLED_PRESETS_FILE" ]]; then
    cat "$INSTALLED_PRESETS_FILE" | sort | uniq
  fi
}

is_preset_installed() {
  local preset="$1"
  if [[ -f "$INSTALLED_PRESETS_FILE" ]]; then
    grep -Fxq "$preset" "$INSTALLED_PRESETS_FILE" 2>/dev/null
  else
    return 1
  fi
}

apply_preset() {
  local preset="$1"
  local skip_dependencies="${2:-false}"
  local parent_preset="${3:-}"
  local indent_level="${4:-0}"
  local preset_file="${PRESETS_DIR}/${preset}.yaml"
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
    if [[ -n "$parent_preset" ]]; then
      dependency_msg "$child_indent" "Depends on: $preset (already applied, skipping explicit re-application for $parent_preset)"
    else
      info_italic_msg "$child_indent" "Preset '$preset' already applied, skipping."
    fi
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    indented_warning "$child_indent" "jq is required. Attempting to install..."
    if command -v brew &>/dev/null; then
      if brew install jq >/dev/null 2>&1; then
        success_tick_msg "$child_indent" "jq installed successfully via Homebrew."
      else
        indented_error_msg "$child_indent" "Failed to install jq via Homebrew."
        return 1
      fi
    else
      indented_error_msg "$child_indent" "Homebrew not found. Cannot install jq automatically."
      return 1
    fi
  fi

  if ! command -v yq &>/dev/null; then
    indented_warning "$child_indent" "yq is required. Attempting to install..."
    if command -v brew &>/dev/null; then
      if brew install yq >/dev/null 2>&1; then
        success_tick_msg "$child_indent" "yq installed successfully via Homebrew."
      else
        indented_error_msg "$child_indent" "Failed to install yq via Homebrew."
        return 1
      fi
    else
      indented_error_msg "$child_indent" "Homebrew not found. Cannot install yq automatically."
      return 1
    fi
  fi

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
        else
          dependency_msg "$child_indent" "Depends on: $dependency (already applied, skipping explicit re-application for $preset)"
        fi
      done
    fi
  fi

  local brew_categories_str
  brew_categories_str=$(yq eval '.homebrew.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$brew_categories_str" && "$brew_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_brew_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$brew_categories_str")
  fi

  local pipx_categories_str
  pipx_categories_str=$(yq eval '.pipx.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$pipx_categories_str" && "$pipx_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_pipx_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$pipx_categories_str")
  fi

  local mas_categories_str
  mas_categories_str=$(yq eval '.mas.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$mas_categories_str" && "$mas_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_mas_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$mas_categories_str")
  fi

  local vscode_categories_str
  vscode_categories_str=$(yq eval '.vscode.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$vscode_categories_str" && "$vscode_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_vscode_extensions "$category" "$child_indent"
    done < <(printf '%s\n' "$vscode_categories_str")
  fi

  local npm_categories_str
  npm_categories_str=$(yq eval '.npm.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$npm_categories_str" && "$npm_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_npm_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$npm_categories_str")
  fi

  local go_categories_str
  go_categories_str=$(yq eval '.go.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$go_categories_str" && "$go_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_go_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$go_categories_str")
  fi

  local cargo_categories_str
  cargo_categories_str=$(yq eval '.cargo.packages[]?' "$preset_file" 2>/dev/null)
  if [[ -n "$cargo_categories_str" && "$cargo_categories_str" != "null" ]]; then
    while IFS= read -r category; do
      install_cargo_packages "$category" "$child_indent"
    done < <(printf '%s\n' "$cargo_categories_str")
  fi

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
  if [[ -d "$PRESETS_DIR" ]]; then
    local count=0
    for file in "$PRESETS_DIR"/*.yaml; do
      if [[ -f "$file" ]]; then
        local preset_name
        preset_name=$(basename "$file" .yaml)
        if [[ "$file" == "$PRESETS_DIR/components/"* ]]; then
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
    indented_info 0 "(No presets directory found at $PRESETS_DIR)"
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
  local script_path="${DOTFILES_DIR}/scripts/${script_name}"

  step_header "$indent_level" "Executing custom script: $script_name"

  if [[ ! -f "$script_path" ]]; then
    indented_error_msg "$indent_level" "Script not found: $script_path"
    return 1
  fi

  if [[ ! -x "$script_path" ]]; then
    action_msg "$indent_level" "Making script executable..."
    if chmod +x "$script_path"; then
      success_tick_msg "$((indent_level+1))" "Script made executable"
    else
      indented_error_msg "$indent_level" "Failed to make script executable: $script_path"
      return 1
    fi
  fi

  action_msg "$indent_level" "Running script for preset: $preset"
  if "$script_path" "$preset" "$DOTFILES_DIR" "$indent_level"; then
    success_tick_msg "$indent_level" "Script '$script_name' executed successfully"
  else
    indented_error_msg "$indent_level" "Script '$script_name' failed with exit code $?"
    return 1
  fi
}
