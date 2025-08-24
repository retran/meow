#!/usr/bin/env bash
source "${MEOW}/lib/core/ui.sh"

if [[ -n "${_LIB_COMPONENTS_PACKAGES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_PACKAGES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/mas.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/pacman.sh"
source "${MEOW}/lib/package/pipx.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/vscode.sh"

install_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [[ ! -d "$packages_dir" ]]; then
    return 0
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Installing packages for component '%s'" "$component")"
  elif [[ "$MEOW_DRY_RUN" = "true" ]]; then
    ui_step_header "$(_f "Dry run: Would install packages for component '%s'" "$component")"
  fi

  local has_packages=false
  local package_errors=0

  if [[ "$IS_MACOS" = "true" ]]; then
    if [[ -f "${packages_dir}/homebrew.list" ]]; then
      if _install_packages_for_component_manager "$component" "homebrew"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
    if [[ -f "${packages_dir}/mas.list" ]]; then
      if _install_packages_for_component_manager "$component" "mas"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
  elif [[ "$IS_DEBIAN_BASED" = "true" ]]; then
    if [[ -f "${packages_dir}/apt.list" ]]; then
      if _install_packages_for_component_manager "$component" "apt"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
  elif [[ "$IS_ALPINE" = "true" ]]; then
    if [[ -f "${packages_dir}/apk.list" ]]; then
      if _install_packages_for_component_manager "$component" "apk"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
  elif [[ "$IS_ARCH" = "true" ]]; then
    if [[ -f "${packages_dir}/pacman.list" ]]; then
      if _install_packages_for_component_manager "$component" "pacman"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
  fi

  for mgr in pipx npm go cargo vscode; do
    if [[ -f "${packages_dir}/${mgr}.list" ]]; then
      if _install_packages_for_component_manager "$component" "$mgr"; then
        has_packages=true
      else
        ((package_errors++))
      fi
    fi
  done

  if [[ "$has_packages" = "true" && "$MEOW_VERBOSE" != "true" ]]; then
    if [[ "$package_errors" -gt 0 ]]; then
      ui_indent "$(_f "Packages for '%s': ✗ %d errors occurred" "$component" "$package_errors")"
    elif [[ "$MEOW_DRY_RUN" != "true" ]]; then
      ui_indent "$(_f "Packages for '%s': ✓ All packages processed successfully." "$component")"
    fi
  fi

  if [[ "$package_errors" -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

uninstall_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [[ ! -d "$packages_dir" ]]; then
    return 0
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Uninstalling packages for component '%s'" "$component")"
  elif [[ "$MEOW_DRY_RUN" = "true" ]]; then
    ui_step_header "$(_f "Dry run: Would uninstall packages for component '%s'" "$component")"
  fi

  if [[ "$IS_MACOS" = "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "homebrew"
    _uninstall_packages_for_component_manager "$component" "mas"
  elif [[ "$IS_DEBIAN_BASED" = "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apt"
  elif [[ "$IS_ALPINE" = "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apk"
  elif [[ "$IS_ARCH" = "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "pacman"
  fi

  for mgr in pipx npm go cargo vscode; do
    _uninstall_packages_for_component_manager "$component" "$mgr"
  done

  if [[ "$MEOW_VERBOSE" != "true" ]]; then
    if [[ "$MEOW_DRY_RUN" != "true" ]]; then
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

  declare -F "$fn" >/dev/null || return 0

  [[ -f "$packages_file" ]] || return 0

  "$fn" "$component"
}

_install_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="install_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  declare -F "$fn" >/dev/null || return 0

  [[ -f "$packages_file" ]] || return 0

  "$fn" "$component"
  return $?
}

_get_component_file_path() {
  local component="$1"
  if [[ "$component" = components/* ]]; then
    local component_name="${component#components/}"
    echo "${MEOW_COMPONENTS_DIR}/${component_name}/component.yaml"
  else
    echo "${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  fi
}

_update_package_manager() {
  local manager_name="$1"
  local cli_command="$2"
  local component="$3"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"

  if ! command -v "$cli_command" >/dev/null 2>&1; then
    return 0
  fi

  if [[ ! -f "$packages_file" ]]; then
    return 0
  fi

  local update_function_name="update_${manager_name}_packages"
  if ! declare -F "$update_function_name" >/dev/null; then
    ui_action_error "$(_f "Update function %s not found for component '%s'." "$update_function_name" "$component")"
    return 1
  fi

  "$update_function_name" "$component"
}

update_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"

  if [[ ! -d "$component_dir" ]]; then
    ui_error "$(_f "Component directory not found: %s" "$component_dir")"
    return 1
  fi

  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_step_header "$(_f "Updating packages for component '%s'" "$component")"
  elif [[ "$MEOW_DRY_RUN" = "true" ]]; then
    ui_step_header "$(_f "Dry run: Would update packages for component '%s'" "$component")"
  fi

  local package_errors=0
  local has_packages=false

  if [[ "$IS_MACOS" = "true" ]]; then
    if _update_package_manager "homebrew" "brew" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
    if _update_package_manager "mas" "mas" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
  elif [[ "$IS_DEBIAN_BASED" = "true" ]]; then
    if _update_package_manager "apt" "apt" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
  elif [[ "$IS_ALPINE" = "true" ]]; then
    if _update_package_manager "apk" "apk" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
  elif [[ "$IS_ARCH" = "true" ]]; then
    if _update_package_manager "pacman" "pacman" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
  fi

  for mgr in pipx npm go cargo vscode; do
    if _update_package_manager "$mgr" "$mgr" "$component"; then
      has_packages=true
    else
      ((package_errors++))
    fi
  done

  if [[ "$has_packages" = "true" && "$MEOW_VERBOSE" != "true" ]]; then
    if [[ "$package_errors" -gt 0 ]]; then
      ui_indent "$(_f "Package updates for '%s': ✗ %d errors occurred" "$component" "$package_errors")"
    elif [[ "$MEOW_DRY_RUN" != "true" ]]; then
      ui_indent "$(_f "Package updates for '%s': ✓ All updates processed successfully." "$component")"
    fi
  fi

  if [[ "$package_errors" -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}
