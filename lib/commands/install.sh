#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ -n "${_LIB_COMMANDS_INSTALL_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_INSTALL_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/presets.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"

_initialize_install_session() {
  local indent=0
  step_header "$indent" "Initializing package manager"

  if [[ "$IS_ALPINE" == "true" ]]; then
    indented_info "$((indent + 1))" "Alpine Linux detected. Using apk."
    setup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    indented_info "$((indent + 1))" "Debian-based system detected. Using APT."
    setup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    indented_info "$((indent + 1))" "macOS system detected. Using Homebrew."
    setup_homebrew "$((indent + 1))"
  else
    indented_warning "$((indent + 1))" "No supported package manager found for this OS. Skipping system setup."
    return 1
  fi

  local yi=$((indent + 1))
  if ! command -v yq >/dev/null 2>&1; then
    indented_info "$yi" "Installing yq..."
    if [[ "$IS_MACOS" == "true" ]]; then
      brew install yq >/dev/null 2>&1 &&
        success_tick_msg "$yi" "yq installed via Homebrew" ||
        indented_error_msg "$yi" "Failed to install yq via Homebrew"
    else
      local arch
      arch=$(uname -m)
      case "$arch" in
        x86_64) arch=amd64 ;;
        aarch64) arch=arm64 ;;
        arm64) arch=arm64 ;;
        *) arch=amd64 ;;
      esac
      local url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}"
      sudo wget -q "$url" -O /usr/local/bin/yq &&
        sudo chmod +x /usr/local/bin/yq &&
        success_tick_msg "$yi" "yq v4 downloaded (${arch})" ||
        indented_error_msg "$yi" "Failed to download yq binary"
    fi
  fi
}

_finalize_install_session() {
  local indent=0

  if [[ "$IS_ALPINE" == "true" ]]; then
    cleanup_apk "$((indent + 1))"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    cleanup_apt "$((indent + 1))"
  elif [[ "$IS_MACOS" == "true" ]]; then
    cleanup_homebrew "$((indent + 1))"
  fi
}

_get_available_presets() {
  for file in "${MEOW}/presets"/*.yaml; do
    [[ -f "$file" ]] && echo "$(basename "$file" .yaml)"
  done
}

_validate_preset_exists() {
  local preset="$1"
  local indent_level="$2"
  local available=()
  while IFS= read -r p; do
    [[ -n "$p" ]] && available+=("$p")
  done < <(_get_available_presets)

  if [[ " ${available[*]} " =~ " ${preset} " ]]; then
    info "$indent_level" "Found preset: $preset"
    return 0
  else
    indented_warning "$indent_level" "Preset '$preset' not found. Available presets:"
    for p in "${available[@]}"; do
      list_item_msg "$((indent_level + 1))" "$p"
    done
    return 1
  fi
}

_install_preset_content() {
  local preset="$1"
  local indent_level="$2"
  apply_preset "$preset" "" "" "$indent_level" || return 1
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

  _initialize_install_session || {
    indented_error_msg "$indent" "Initialization failed"
    return 1
  }

  _install_preset_content "$preset" "$indent" || return 1
  _finalize_install_session
  _report_install_results "$preset" "$indent"
}
