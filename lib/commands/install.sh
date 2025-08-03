#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_COMMANDS_INSTALL_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_INSTALL_SOURCED=1

# Source all dependencies: UI, presets, and all package manager libraries
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/presets.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"

# Dynamically initialize the correct package manager based on OS
_initialize_install_session() {
  local indent=0
  step_header "$indent" "Initializing package manager"

  # IS_DEBIAN_BASED is set in apt.sh
  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    indented_info "$((indent + 1))" "Debian-based system detected. Using APT."
    setup_apt "$((indent + 1))"
  # IS_MACOS is set in homebrew.sh
  elif [[ "$IS_MACOS" == "true" ]]; then
    indented_info "$((indent + 1))" "macOS system detected. Using Homebrew."
    setup_homebrew "$((indent + 1))"
  else
    indented_warning "$((indent + 1))" "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi
}

# Dynamically clean up using the correct package manager based on OS
_finalize_install_session() {
  local indent=0

  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew "$((indent + 1))"
  fi
}

_get_available_presets() {
  for file in "${MEOW}/presets"/*.yaml; do
    if [[ -f "$file" ]]; then
      echo "$(basename "$file" .yaml)"
    fi
  done
}

_validate_preset_exists() {
  local preset="$1"
  local indent_level="$2"
  local available_presets=()

  while IFS= read -r preset_name; do
    if [[ -n "$preset_name" ]]; then
      available_presets+=("$preset_name")
    fi
  done < <(_get_available_presets)

  if [[ " ${available_presets[*]} " =~ " ${preset} " ]]; then
    info "$indent_level" "Found preset: $preset"
    return 0
  else
    indented_warning "$indent_level" "Preset '$preset' not found. Available presets:"
    for preset_name in "${available_presets[@]}"; do
      list_item_msg "$((indent_level + 1))" "$preset_name"
    done
    return 1
  fi
}

_install_preset_content() {
  local preset="$1"
  local indent_level="$2"

  if ! apply_preset "$preset" "" "" "$indent_level"; then
    return 1
  fi

  save_installed_preset "$preset"
}

_report_install_results() {
  local preset="$1"
  local indent_level="$2"

  success_tick_msg "$indent_level" "Installation completed successfully with preset: $preset"
  info "$indent_level" "You may need to restart your shell for all changes to take effect."
  info "$indent_level" "Run 'source ~/.zshrc' or 'source ~/.bashrc' to reload your shell configuration."
}

install_preset() {
  local preset="$1"
  local indent=0

  header "$indent" "Installing meow with preset: $preset"

  _validate_preset_exists "$preset" "$indent" || return 1

  if ! _initialize_install_session; then
    indented_error_msg "$indent" "Failed to initialize a package manager. Aborting installation."
    return 1
  fi

  _install_preset_content "$preset" "$indent" || return 1
  _finalize_install_session

  _report_install_results "$preset" "$indent"
}
