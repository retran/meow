#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ -n "${_LIB_COMMANDS_INSTALL_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_INSTALL_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/session.sh"
source "${MEOW}/lib/core/tools.sh"
source "${MEOW}/lib/package/presets.sh"

_get_available_presets() {
  for file in "${MEOW}/presets"/*.yaml; do
    [[ -f "$file" ]] && echo "$(basename "$file" .yaml)"
  done
}

_validate_preset_exists() {
  local preset="$1"
  local indent="$2"
  local available=()
  while IFS= read -r p; do [[ -n "$p" ]] && available+=("$p"); done < <(_get_available_presets)

  if [[ " ${available[*]} " =~ " ${preset} " ]]; then
    info "$indent" "Found preset: $preset"
    return 0
  else
    indented_warning "$indent" "Preset '$preset' not found. Available presets:"
    for p in "${available[@]}"; do list_item_msg "$((indent + 1))" "$p"; done
    return 1
  fi
}

_install_preset_content() {
  local preset="$1"
  local indent="$2"
  apply_preset "$preset" "" "" "$indent" || return 1
  save_installed_preset "$preset"
}

_report_install_results() {
  local preset="$1"
  local indent="$2"
  success_tick_msg "$indent" "Installation completed successfully with preset: $preset"
  info "$indent" "Restart your shell or run 'source ~/.zshrc' / 'source ~/.bashrc'."
}

install_preset() {
  local preset="$1"
  local indent=0

  header "$indent" "Installing meow with preset: $preset"
  _validate_preset_exists "$preset" "$indent" || return 1
  _initialize_session || {
    indented_error_msg "$indent" "Init failed"
    return 1
  }
  _install_preset_content "$preset" "$indent" || return 1
  _finalize_session
  _report_install_results "$preset" "$indent"
}
