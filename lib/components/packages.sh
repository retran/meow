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
# @file: lib/components/packages.sh
# @brief: Package installation and management for components across platform package managers.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

if [ -n "${_LIB_COMPONENTS_PACKAGES_SOURCED:-}" ]; then
  return 0
fi
_LIB_COMPONENTS_PACKAGES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/package/config.sh"
source "${MEOW}/lib/package/sources.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/mas.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/pacman.sh"
source "${MEOW}/lib/package/dnf.sh"
source "${MEOW}/lib/package/pipx.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/vscode.sh"
source "${MEOW}/lib/package/snap.sh"

install_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [ ! -d "$component_dir" ]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [ ! -d "$packages_dir" ]; then
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Installing packages for component '%s'" "$component")"
  elif [ "$MEOW_DRY_RUN" = "true" ]; then
    ui_step_header "$(_f "Dry run: Would install packages for component '%s'" "$component")"
  fi

  local has_packages=false
  local package_errors=0
  local active_managers
  active_managers="$(meow_pm_resolve_for_component "$component")"

  if [ "$IS_MACOS" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "homebrew" && [ -f "${packages_dir}/homebrew.list" ]; then
      apply_component_sources "$component" "homebrew"
      if _install_packages_for_component_manager "$component" "homebrew"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
    if meow_pm_should_use_manager "$active_managers" "mas" && [ -f "${packages_dir}/mas.list" ]; then
      apply_component_sources "$component" "mas"
      if _install_packages_for_component_manager "$component" "mas"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  elif meow_os_is_like "debian"; then
    if meow_pm_should_use_manager "$active_managers" "apt" && [ -f "${packages_dir}/apt.list" ]; then
      apply_component_sources "$component" "apt"
      if _install_packages_for_component_manager "$component" "apt"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  elif [ "$IS_RPM_BASED" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "dnf" && [ -f "${packages_dir}/dnf.list" ]; then
      apply_component_sources "$component" "dnf"
      if _install_packages_for_component_manager "$component" "dnf"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  elif [ "$IS_ALPINE" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "apk" && [ -f "${packages_dir}/apk.list" ]; then
      if _install_packages_for_component_manager "$component" "apk"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  elif [ "$IS_ARCH" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "pacman" && [ -f "${packages_dir}/pacman.list" ]; then
      if _install_packages_for_component_manager "$component" "pacman"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  fi

  for mgr in pipx npm go cargo vscode snap; do
    if meow_pm_should_use_manager "$active_managers" "$mgr" && [ -f "${packages_dir}/${mgr}.list" ]; then
      if _install_packages_for_component_manager "$component" "$mgr"; then
        has_packages=true
      else
        package_errors=$((package_errors + 1))
      fi
    fi
  done

  if [ "$has_packages" = "true" ] && [ "$MEOW_VERBOSE" != "true" ]; then
    if [ "$package_errors" -gt 0 ]; then
      ui_indent "$(_f "Packages for '%s': ✗ %d errors occurred" "$component" "$package_errors")"
    elif [ "$MEOW_DRY_RUN" != "true" ]; then
      ui_indent "$(_f "Packages for '%s': ✓ All packages processed successfully." "$component")"
    fi
  fi

  if [ "$package_errors" -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

uninstall_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [ ! -d "$component_dir" ]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [ ! -d "$packages_dir" ]; then
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Uninstalling packages for component '%s'" "$component")"
  elif [ "$MEOW_DRY_RUN" = "true" ]; then
    ui_step_header "$(_f "Dry run: Would uninstall packages for component '%s'" "$component")"
  fi

  local active_managers
  active_managers="$(meow_pm_resolve_for_component "$component")"

  if [ "$IS_MACOS" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "homebrew"; then
      _uninstall_packages_for_component_manager "$component" "homebrew"
    fi
    if meow_pm_should_use_manager "$active_managers" "mas"; then
      _uninstall_packages_for_component_manager "$component" "mas"
    fi
  elif meow_os_is_like "debian"; then
    if meow_pm_should_use_manager "$active_managers" "apt"; then
      _uninstall_packages_for_component_manager "$component" "apt"
    fi
  elif [ "$IS_RPM_BASED" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "dnf"; then
      _uninstall_packages_for_component_manager "$component" "dnf"
    fi
  elif [ "$IS_ALPINE" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "apk"; then
      _uninstall_packages_for_component_manager "$component" "apk"
    fi
  elif [ "$IS_ARCH" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "pacman"; then
      _uninstall_packages_for_component_manager "$component" "pacman"
    fi
  fi

  for mgr in pipx npm go cargo vscode snap; do
    if meow_pm_should_use_manager "$active_managers" "$mgr"; then
      _uninstall_packages_for_component_manager "$component" "$mgr"
    fi
  done

  if [ "$MEOW_VERBOSE" != "true" ]; then
    if [ "$MEOW_DRY_RUN" != "true" ]; then
      ui_indent "$(_f "Packages for '%s': ✓ Uninstallation processed successfully." "$component")"
    fi
  fi

  return 0
}

_uninstall_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="uninstall_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  command -v "$fn" >/dev/null 2>&1 || return 0

  [ -f "$packages_file" ] || return 0

  "$fn" "$component"
}

_resolve_packages_file() {
  local component="$1"
  local mgr="$2"
  local path="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"
  [ -f "$path" ] || return 1
  echo "$path"
}

_install_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="install_${mgr}_packages"
  local packages_file
  packages_file=$(_resolve_packages_file "$component" "$mgr") || return 0

  command -v "$fn" >/dev/null 2>&1 || return 0

  PACKAGES_OVERRIDE_FILE="$packages_file" "$fn" "$component"
  return $?
}

_get_component_file_path() {
  local component="$1"
  case "$component" in
    components/*)
      local component_name="${component#components/}"
      echo "${MEOW_COMPONENTS_DIR}/${component_name}/component.yaml"
      ;;
    *)
      echo "${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
      ;;
  esac
}

_update_package_manager() {
  local manager_name="$1"
  local cli_command="$2"
  local component="$3"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"

  if [ "$manager_name" = "dnf" ]; then
    cli_command=$(_get_dnf_command) || return 0
  fi

  if ! command -v "$cli_command" >/dev/null 2>&1; then
    return 0
  fi

  if [ ! -f "$packages_file" ]; then
    return 0
  fi

  local update_function_name="update_${manager_name}_packages"
  if ! command -v "$update_function_name" >/dev/null 2>&1; then
    ui_action_error "$(_f "Update function %s not found for component '%s'." "$update_function_name" "$component")"
    return 1
  fi

  "$update_function_name" "$component"
}

update_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"

  if [ ! -d "$component_dir" ]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Updating packages for component '%s'" "$component")"
  elif [ "$MEOW_DRY_RUN" = "true" ]; then
    ui_step_header "$(_f "Dry run: Would update packages for component '%s'" "$component")"
  fi

  local package_errors=0
  local has_packages=false
  local active_managers
  active_managers="$(meow_pm_resolve_for_component "$component")"

  if [ "$IS_MACOS" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "homebrew"; then
      apply_component_sources "$component" "homebrew"
    fi
    if meow_pm_should_use_manager "$active_managers" "homebrew" && _update_package_manager "homebrew" "brew" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "homebrew"; then
      package_errors=$((package_errors + 1))
    fi
    if meow_pm_should_use_manager "$active_managers" "mas"; then
      apply_component_sources "$component" "mas"
    fi
    if meow_pm_should_use_manager "$active_managers" "mas" && _update_package_manager "mas" "mas" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "mas"; then
      package_errors=$((package_errors + 1))
    fi
  elif meow_os_is_like "debian"; then
    if meow_pm_should_use_manager "$active_managers" "apt"; then
      apply_component_sources "$component" "apt"
    fi
    if meow_pm_should_use_manager "$active_managers" "apt" && _update_package_manager "apt" "apt" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "apt"; then
      package_errors=$((package_errors + 1))
    fi
  elif [ "$IS_RPM_BASED" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "dnf"; then
      apply_component_sources "$component" "dnf"
    fi
    if meow_pm_should_use_manager "$active_managers" "dnf" && _update_package_manager "dnf" "dnf" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "dnf"; then
      package_errors=$((package_errors + 1))
    fi
  elif [ "$IS_ALPINE" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "apk" && _update_package_manager "apk" "apk" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "apk"; then
      package_errors=$((package_errors + 1))
    fi
  elif [ "$IS_ARCH" = "true" ]; then
    if meow_pm_should_use_manager "$active_managers" "pacman" && _update_package_manager "pacman" "pacman" "$component"; then
      has_packages=true
    elif meow_pm_should_use_manager "$active_managers" "pacman"; then
      package_errors=$((package_errors + 1))
    fi
  fi

  for mgr in pipx npm go cargo vscode snap; do
    if ! meow_pm_should_use_manager "$active_managers" "$mgr"; then
      continue
    fi
    if _update_package_manager "$mgr" "$mgr" "$component"; then
      has_packages=true
    else
      package_errors=$((package_errors + 1))
    fi
  done

  if [ "$has_packages" = "true" ] && [ "$MEOW_VERBOSE" != "true" ]; then
    if [ "$package_errors" -gt 0 ]; then
      ui_indent "$(_f "Package updates for '%s': ✗ %d errors occurred" "$component" "$package_errors")"
    elif [ "$MEOW_DRY_RUN" != "true" ]; then
      ui_indent "$(_f "Package updates for '%s': ✓ All updates processed successfully." "$component")"
    fi
  fi

  if [ "$package_errors" -eq 0 ]; then
    return 0
  else
    return 1
  fi
}
