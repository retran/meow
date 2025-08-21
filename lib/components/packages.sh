#!/usr/bin/env bash

if [[ -n "${_LIB_COMPONENTS_PACKAGES_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMPONENTS_PACKAGES_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/ui.sh"
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

# Install all packages defined for a component across applicable package managers
# Args:
#   $1 - component name
install_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    error "Component directory not found: $component_dir"
    return 1
  fi

  # Проверяем, есть ли папка packages
  if [[ ! -d "$packages_dir" ]]; then
    # Если нет папки packages, значит компонент не требует установки пакетов
    return 0
  fi

  # Show packages section header only in verbose mode
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Installing packages for $component"
  fi

  local has_packages=false
  local package_errors=0

  # Install packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    if [[ -f "${packages_dir}/homebrew.list" ]]; then
      if _install_packages_for_component_manager "$component" "homebrew"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
    if [[ -f "${packages_dir}/mas.list" ]]; then
      if _install_packages_for_component_manager "$component" "mas"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    if [[ -f "${packages_dir}/apt.list" ]]; then
      if _install_packages_for_component_manager "$component" "apt"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_ALPINE" == "true" ]]; then
    if [[ -f "${packages_dir}/apk.list" ]]; then
      if _install_packages_for_component_manager "$component" "apk"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  elif [[ "$IS_ARCH" == "true" ]]; then
    if [[ -f "${packages_dir}/pacman.list" ]]; then
      if _install_packages_for_component_manager "$component" "pacman"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  fi

  # Install packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    if [[ -f "${packages_dir}/${mgr}.list" ]]; then
      if _install_packages_for_component_manager "$component" "$mgr"; then
        has_packages=true
      else
        ((package_errors++)) || true
      fi
    fi
  done

  # Show compact summary if we had packages and we're not in verbose mode
  if [[ "$has_packages" == "true" && "$MEOW_VERBOSE" != "true" ]]; then
    if [[ $package_errors -gt 0 ]]; then
      indent_msg "Packages: ✗ $package_errors errors occurred"
    fi
  fi

  return $([[ $package_errors -eq 0 ]] && echo 0 || echo 1)
}

# Uninstall all packages defined for a component across applicable package managers
# Args:
#   $1 - component name
uninstall_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"
  local packages_dir="${component_dir}/packages"

  if [[ ! -d "$component_dir" ]]; then
    error "Component directory not found: $component_dir"
    return 1
  fi

  # Проверяем, есть ли папка packages
  if [[ ! -d "$packages_dir" ]]; then
    # Если нет папки packages, значит компонент не требует удаления пакетов
    return 0
  fi

  # Uninstall packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "homebrew"
    _uninstall_packages_for_component_manager "$component" "mas"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apt"
  elif [[ "$IS_ALPINE" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "apk"
  elif [[ "$IS_ARCH" == "true" ]]; then
    _uninstall_packages_for_component_manager "$component" "pacman"
  fi

  # Uninstall packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    _uninstall_packages_for_component_manager "$component" "$mgr"
  done

  return 0
}

# Helper: uninstall packages for a specific package manager
# Args:
#   $1 - component name
#   $2 - package manager name
_uninstall_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="uninstall_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  # Skip if package manager uninstall function doesn't exist
  declare -F "$fn" >/dev/null || return

  # Skip if package file doesn't exist
  [[ -f "$packages_file" ]] || return

  # Call the uninstall function with component name
  "$fn" "$component"
}

# Helper: install packages for a specific package manager
# Args:
#   $1 - component name
#   $2 - package manager name
_install_packages_for_component_manager() {
  local component="$1"
  local mgr="$2"
  local fn="install_${mgr}_packages"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"

  # Skip if package manager install function doesn't exist
  declare -F "$fn" >/dev/null || return 0

  # Skip if package file doesn't exist
  [[ -f "$packages_file" ]] || return 0

  # Call the install function with component name and return its exit code
  "$fn" "$component"
  return $?
}

# Helper: Get normalized path to component file
# Args: $1 - component name (may include "components/" prefix)
# Returns: Absolute path to component.yaml file
_get_component_file_path() {
  local component="$1"
  if [[ "$component" == components/* ]]; then
    local component_name="${component#components/}"
    echo "${MEOW_COMPONENTS_DIR}/${component_name}/component.yaml"
  else
    echo "${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  fi
}

# Update packages for a specific package manager within a component
# Args:
#   $1 - package manager name (e.g., "homebrew", "apt", "npm")
#   $2 - CLI command name for the package manager
#   $3 - component name
_update_package_manager() {
  local manager_name="$1"
  local cli_command="$2"
  local component="$3"
  local packages_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"

  # Skip if package manager CLI is not available
  if ! command -v "$cli_command" >/dev/null 2>&1; then
    return 0
  fi

  # Skip if package file doesn't exist
  if [[ ! -f "$packages_file" ]]; then
    return 0
  fi

  # Check if update function exists for this package manager
  local update_function_name="update_${manager_name}_packages"
  if ! declare -F "$update_function_name" >/dev/null; then
    error_msg "Update function ${update_function_name} not found."
    return 1
  fi

  # Call the update function with component name
  "$update_function_name" "$component"
}

# Update all packages for a component across all applicable package managers
# Args:
#   $1 - component name
update_component_packages() {
  local component="$1"
  local component_dir="${MEOW_COMPONENTS_DIR}/${component}"

  if [[ ! -d "$component_dir" ]]; then
    error "Component directory not found: $component_dir"
    return 1
  fi

  # Show packages section header only in verbose mode
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "Updating packages for $component"
  fi

  local package_errors=0
  local has_packages=false

  # Update packages for platform-specific package managers
  if [[ "$IS_MACOS" == "true" ]]; then
    if _update_package_manager "homebrew" "brew" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
    if _update_package_manager "mas" "mas" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    if _update_package_manager "apt" "apt" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
  elif [[ "$IS_ALPINE" == "true" ]]; then
    if _update_package_manager "apk" "apk" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
  elif [[ "$IS_ARCH" == "true" ]]; then
    if _update_package_manager "pacman" "pacman" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
  fi

  # Update packages for cross-platform managers
  for mgr in pipx npm go cargo vscode; do
    if _update_package_manager "$mgr" "$mgr" "$component"; then
      has_packages=true
    else
      ((package_errors++)) || true
    fi
  done

  # Show compact summary if we had packages and we're not in verbose mode
  if [[ "$has_packages" == "true" && "$MEOW_VERBOSE" != "true" ]]; then
    if [[ $package_errors -gt 0 ]]; then
      indent_msg "Package updates: ✗ $package_errors errors occurred"
    fi
  fi

  return $([[ $package_errors -eq 0 ]] && echo 0 || echo 1)
}
