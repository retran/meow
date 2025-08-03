#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ -n "${_LIB_COMMANDS_INSTALL_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_INSTALL_SOURCED=1

source "${MEOW}/lib/commands/session.sh"
source "${MEOW}/lib/package/presets.sh"

_validate_preset_exists() {
  local preset="$1" indent="$2"
  local found=false
  for f in "${MEOW}/presets"/*.yaml; do
    [[ "$(basename "$f" .yaml)" == "$preset" ]] && found=true
  done
  if [[ "$found" == true ]]; then
    info "$indent" "Found preset: $preset"
    return 0
  else
    indented_error_msg "$indent" "Preset '$preset' not found"
    return 1
  fi
}

install_preset() {
  local preset="$1"
  local indent=0

  header "$indent" "Installing meow with preset: $preset"
  _validate_preset_exists "$preset" "$indent" || return 1

  _initialize_session "Initializing package manager" || return 1

  apply_preset "$preset" "" "" "$indent" || return 1
  save_installed_preset "$preset"

  _finalize_session

  success_tick_msg "$indent" "Installation completed successfully with preset: $preset"
  info "$indent" "Restart your shell or run 'source ~/.zshrc' or 'source ~/.bashrc'."
}
