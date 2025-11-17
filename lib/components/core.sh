#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/components/core.sh
# @brief: Core component installation, status checking, and symlink management.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

if [ -n "${_LIB_COMPONENTS_CORE_SOURCED:-}" ]; then
  return 0
fi
_LIB_COMPONENTS_CORE_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/colors.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/tools.sh"

is_component_installed() {
  local component="$1"
  [ -L "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}" ]
}

is_component_manually_installed() {
  local component="$1"
  [ -L "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" ]
}

install_component_symlink() {
  local component="$1"
  local component_path="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  if [ ! -f "$component_path" ]; then
    ui_error "$(_f "Component file not found: %s" "$component_path")"
    return 1
  fi

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would create symlink for component '%s': %s -> %s" "$component" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}" "${MEOW_COMPONENTS_DIR}/${component}")"
    if [ "${MEOW_COMPONENT_MANUAL_INSTALL:-}" = "true" ]; then
      dry_run_ui_info "$(_f "Would mark component '%s' as manually installed: %s -> %s" "$component" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" "${MEOW_COMPONENTS_DIR}/${component}")"
    fi
    return 0
  fi

  mkdir -p "$MEOW_INSTALLED_COMPONENTS_DIR" || {
    ui_error "$(_f "Failed to create installed components directory.")"
    return 1
  }
  ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}" || {
    ui_error "$(_f "Failed to create symlink for component '%s'." "$component")"
    return 1
  }

  if [ "${MEOW_COMPONENT_MANUAL_INSTALL:-}" = "true" ]; then
    mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR" || {
      ui_error "$(_f "Failed to create manually installed components directory.")"
      return 1
    }
    ln -s "${MEOW_COMPONENTS_DIR}/${component}" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}" || {
      ui_error "$(_f "Failed to mark component '%s' as manually installed." "$component")"
      return 1
    }
  fi
}

remove_component_symlink() {
  local component="$1"

  if is_dry_run; then
    dry_run_ui_info "$(_f "Would remove symlink for component '%s': %s" "$component" "${MEOW_INSTALLED_COMPONENTS_DIR}/${component}")"
    dry_run_ui_info "$(_f "Would remove manual install marker for component '%s': %s" "$component" "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component}")"
    return 0
  fi

  rm -rf "${MEOW_INSTALLED_COMPONENTS_DIR:?}/${component}" || {
    ui_warning "$(_f "Failed to remove installed component symlink for '%s'." "$component")"
  }

  rm -rf "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR:?}/${component}" || {
    ui_warning "$(_f "Failed to remove manual install marker for '%s'." "$component")"
  }
}

is_component_available() {
  local component="$1"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"

  [ -f "$component_file" ] || return 1

  if yaml_path_exists "$component_file" ".platforms"; then
    local platform_json
    platform_json=$(yq -o=json '.platforms // []' "$component_file" 2>/dev/null)
    if [ -n "$platform_json" ]; then
      local platform
      platform=$(get_platform)
      local matches
      matches=$(python3 - "$platform_json" "$platform" "${MEOW_OS_ID:-}" "${MEOW_OS_ID_LIKE// /,}" <<'PY'
import json, sys
entries = json.loads(sys.argv[1] or "[]")
platform = sys.argv[2]
distro = sys.argv[3]
likes = sys.argv[4].split(',') if len(sys.argv) > 4 and sys.argv[4] else []

def to_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return value
    return [value]

for entry in entries:
    if isinstance(entry, str):
        if entry == platform:
            print('1')
            sys.exit(0)
        continue
    match = entry.get('match') or {}
    platforms = to_list(match.get('platform'))
    if platforms and platform not in platforms:
        continue
    distros = to_list(match.get('distro'))
    if distros and distro not in distros:
        continue
    distro_like = to_list(match.get('distro_like'))
    if distro_like and not any(item in likes for item in distro_like):
        continue
    print('1')
    sys.exit(0)
print('0')
PY
)
      if [ "$matches" != "1" ]; then
        return 1
      fi
    fi
  fi

  if yaml_path_exists "$component_file" ".depends_on"; then
    local dependency_name
    while IFS= read -r dependency_name; do
      dependency_name=$(echo "$dependency_name" | tr -d '"')
      if [ -n "$dependency_name" ] && ! is_component_available "$dependency_name"; then
        return 1
      fi
    done < <(read_yaml_array "$component_file" ".depends_on[]" 2>/dev/null)
  fi

  return 0
}

list_components() {
  local show_installed_only="${1:-false}"
  local show_verbose="${2:-true}"

  if [ ! -d "$MEOW_COMPONENTS_DIR" ]; then
    ui_error "$(_f "Components directory not found: %s" "$MEOW_COMPONENTS_DIR")"
    return 1
  fi

  local components_array
  components_array=()
  local i=0
  while IFS= read -r comp_name; do
    if [ -n "$comp_name" ]; then
      components_array[i]="$comp_name"
      i=$((i + 1))
    fi
  done < <(find "$MEOW_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

  local MEOW_COMPONENTS_DIR_BASENAME
  MEOW_COMPONENTS_DIR_BASENAME="$(basename "$MEOW_COMPONENTS_DIR")"

  for component in "${components_array[@]}"; do
    if [ "$component" = "." ] || [ "$component" = "$MEOW_COMPONENTS_DIR_BASENAME" ]; then
      continue
    fi

    local installed="false"
    local status="available"
    local status_color="${BLUE}"
    local status_symbol="○"

    if is_component_installed "$component"; then
      installed="true"
      status="installed"
      status_color="${GREEN}"
      status_symbol="✓"
    fi

    if [ "$show_installed_only" = "true" ] && [ "$installed" = "false" ]; then
      continue
    fi

    if ! is_component_available "$component"; then
      status="incompatible"
      status_color="${RED}"
      status_symbol="✗"
    fi

    if [ "$show_verbose" = "true" ]; then
      if [ "$installed" = "true" ] && is_component_manually_installed "$component"; then
        status="installed (manual)"
      fi

      printf "${status_color}%-2s${RESET} %-30s ${status_color}%s${RESET}\n" "$status_symbol" "$component" "$status"
    else
      echo "$component"
    fi
  done
}

setup_component() {
  local component="$1"
  local component_source_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local init_script="${component_source_dir}/scripts/setup.sh"

  if [ -f "$init_script" ]; then
    _icon_msg_core "${BLUE}➤ " "$(_f "Setting up component: %s" "$component")"

    if dry_run_script_execution "$init_script" "setup script for $component"; then
      return 0
    fi

    if [ ! -x "$init_script" ]; then
      chmod +x "$init_script" || {
        ui_error "$(_f "Failed to make setup script executable for '%s'." "$component")"
        return 1
      }
    fi

    if "$init_script" "$component" "$MEOW"; then
      ui_action_success "$(_f "Component '%s' setup completed successfully." "$component")"
    else
      ui_error "$(_f "Component '%s' setup failed." "$component")"
      return 1
    fi
  else
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "No setup script found for component '%s'." "$component")"
    fi
  fi
}

cleanup_component() {
  local component="$1"
  local component_source_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local cleanup_script="${component_source_dir}/scripts/cleanup.sh"

  if [ -f "$cleanup_script" ]; then
    if [ "$MEOW_VERBOSE" = "true" ]; then
      _icon_msg_core "${YELLOW}➤ " "$(_f "Cleaning component: %s" "$component")"
    fi

    if dry_run_script_execution "$cleanup_script" "cleanup script for $component"; then
      return 0
    fi

    if [ ! -x "$cleanup_script" ]; then
      chmod +x "$cleanup_script" || {
        ui_warning "$(_f "Failed to make cleanup script executable for '%s'." "$component")"
        return 1
      }
    fi

    if "$cleanup_script" "$component" "$MEOW"; then
      ui_verbose_action_success "$(_f "Component '%s' cleanup completed successfully." "$component")"
    else
      ui_warning "$(_f "Component '%s' cleanup failed." "$component")"
      return 1
    fi
  else
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "$(_f "No cleanup script found for component '%s'." "$component")"
    fi
  fi
}
