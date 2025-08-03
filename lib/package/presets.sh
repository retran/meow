#!/usr/bin/env bash

# lib/package/presets.sh - Preset application logic

if [[ -n "${_LIB_PACKAGE_PRESETS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_PRESETS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/pipx.sh"
source "${MEOW}/lib/package/mas.sh"
source "${MEOW}/lib/package/vscode.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"

readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_INSTALLED_PRESETS_FILE="$HOME/.meow_installed_presets"
APPLIED_PRESETS=()

is_preset_applied() {
  local preset="$1"
  for p in "${APPLIED_PRESETS[@]}"; do
    [[ "$p" == "$preset" ]] && return 0
  done
  return 1
}

save_installed_preset() {
  local preset="$1"
  touch "$MEOW_INSTALLED_PRESETS_FILE"
  grep -Fxq "$preset" "$MEOW_INSTALLED_PRESETS_FILE" 2>/dev/null || echo "$preset" >>"$MEOW_INSTALLED_PRESETS_FILE"
}

_ensure_tool_available() {
  local tool="$1" indent="$2"
  command -v "$tool" >/dev/null 2>&1 && return 0
  indented_warning "$indent" "'$tool' required, installing..."
  if [[ "$IS_MACOS" == "true" ]]; then
    brew install "$tool" >/dev/null 2>&1 && success_tick_msg "$indent" "'$tool' installed" || { indented_error_msg "$indent" "Failed to install $tool"; return 1; }
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    sudo apt-get install -y "$tool" >/dev/null 2>&1 && success_tick_msg "$indent" "'$tool' installed" || { indented_error_msg "$indent" "Failed to install $tool"; return 1; }
  elif [[ "$IS_ALPINE" == "true" ]]; then
    sudo apk add --no-cache "$tool" >/dev/null 2>&1 && success_tick_msg "$indent" "'$tool' installed" || { indented_error_msg "$indent" "Failed to install $tool"; return 1; }
  else
    indented_error_msg "$indent" "Cannot install $tool automatically on this OS"
    return 1
  fi
}

_apply_packages_for_manager() {
  local mgr="$1" preset_file="$2" indent="$3"
  local fn="install_${mgr}_packages"
  declare -F "$fn" >/dev/null || return
  local list
  list=$(yq eval ".${mgr}.packages[]?" "$preset_file" 2>/dev/null) || return
  [[ -z "$list" || "$list" == "null" ]] && return
  while IFS= read -r cat; do
    [[ -n "$cat" ]] && "$fn" "$cat" "$indent"
  done < <(printf '%s\n' "$list")
}

apply_preset() {
  local preset="$1" skip_deps="$2" parent="$3" indent="$4"
  local child_indent=$((indent+1))
  local file="${MEOW}/presets/${preset}.yaml"

  _ensure_tool_available "jq" "$child_indent" || return 1
  _ensure_tool_available "yq" "$child_indent" || return 1

  if is_preset_applied "$preset"; then
    info_italic_msg "$child_indent" "Preset '$preset' already applied, skipping."
    return 0
  fi

  if [[ "$skip_deps" != "true" ]]; then
    local deps
    deps=$(yq eval '.depends_on[]?' "$file" 2>/dev/null)
    [[ -n "$deps" && "$deps" != "null" ]] && for d in $deps; do
      apply_preset "$d" false "$preset" "$child_indent"
    done
  fi

  if [[ "$IS_MACOS" == "true" ]]; then
    _apply_packages_for_manager "homebrew" "$file" "$child_indent"
    _apply_packages_for_manager "mas"      "$file" "$child_indent"
  elif [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _apply_packages_for_manager "apt"      "$file" "$child_indent"
  elif [[ "$IS_ALPINE" == "true" ]]; then
    _apply_packages_for_manager "apk"      "$file" "$child_indent"
  fi

  _apply_packages_for_manager "pipx"   "$file" "$child_indent"
  _apply_packages_for_manager "npm"    "$file" "$child_indent"
  _apply_packages_for_manager "go"     "$file" "$child_indent"
  _apply_packages_for_manager "cargo"  "$file" "$child_indent"
  _apply_packages_for_manager "vscode" "$file" "$child_indent"

  local syms
  syms=$(yq eval '.symlinks[]?' "$file" 2>/dev/null)
  [[ -n "$syms" && "$syms" != "null" ]] && \
    for c in $syms; do setup_symlinks "$c" "$child_indent"; done

  local script
  script=$(yq eval '.script?' "$file" 2>/dev/null)
  [[ -n "$script" && "$script" != "null" ]] && execute_preset_script "$script" "$preset" "$child_indent"

  APPLIED_PRESETS+=("$preset")
}
