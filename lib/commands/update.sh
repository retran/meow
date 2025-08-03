#!/usr/bin/env bash

# lib/commands/update.sh - Command library for updating dotfiles

if [[ -n "${_LIB_COMMANDS_UPDATE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_COMMANDS_UPDATE_SOURCED=1

source "${MEOW}/lib/commands/session.sh"
source "${MEOW}/lib/package/presets.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/package/apk.sh"
source "${MEOW}/lib/package/npm.sh"
source "${MEOW}/lib/package/go.sh"
source "${MEOW}/lib/package/cargo.sh"
source "${MEOW}/lib/package/vscode.sh"

UPDATED_PRESETS=""

_check_preset_already_updated() {
  local preset="$1" indent="$2"
  [[ "${UPDATED_PRESETS}" == *"|$preset|"* ]] &&
    {
      info_italic_msg "$indent" "Preset '$preset' already updated, skipping"
      return 0
    }
  return 1
}

_validate_preset_file() {
  local file="$1" indent="$2"
  [[ -f "$file" ]] || {
    indented_error_msg "$indent" "Preset file not found: $file"
    return 1
  }
  return 0
}

_parse_preset_dependencies() {
  local file="$1" var="$2"
  local deps
  deps=$(yq eval '.depends_on[]?' "$file" 2>/dev/null)
  [[ -n "$deps" && "$deps" != "null" ]] &&
    while IFS= read -r d; do [[ -n "$d" ]] && eval "${var}+=(\"$d\")"; done < <(printf '%s\n' "$deps")
}

_update_preset_dependencies() {
  local preset="$1" file="$2" indent="$3"
  local deps=()
  _parse_preset_dependencies "$file" "deps"
  for d in "${deps[@]}"; do
    dependency_msg "$indent" "Updating dependency: $d (for $preset)"
    update_preset_with_dependencies "$d" "$indent"
  done
}

_update_package_manager() {
  local mgr="$1" cmd="$2" preset="$3" indent="$4"
  local file="${MEOW}/presets/${preset}.yaml"
  local list had_updates=false had_errors=false

  command -v "$cmd" >/dev/null 2>&1 || return 100
  list=$(yq eval ".${mgr}.packages[]?" "$file" 2>/dev/null)
  [[ -z "$list" || "$list" == "null" ]] && return 100

  local fn="update_${mgr}_packages"
  declare -F "$fn" >/dev/null || {
    indented_error_msg "$indent" "Function $fn not found"
    return 1
  }

  while IFS= read -r cat; do
    $fn "$cat" "$indent"
    rc=$?
    [[ $rc -eq 0 ]] && had_updates=true
    [[ $rc -eq 1 ]] && had_errors=true
  done < <(printf '%s\n' "$list")

  [[ $had_errors == true ]] && return 1
  [[ $had_updates == true ]] && return 0
  return 100
}

update_preset_packages() {
  local preset="$1" indent="$2"
  local had_updates=false rc

  if [[ "$IS_MACOS" == "true" ]]; then
    _update_package_manager "homebrew" "brew" "$preset" "$indent"
    rc=$? && [[ $rc -eq 0 ]] && had_updates=true
    _update_package_manager "mas" "mas" "$preset" "$indent"
    rc=$? && [[ $rc -eq 0 ]] && had_updates=true
  fi
  if [[ "$IS_DEBIAN_BASED" == "true" ]]; then
    _update_package_manager "apt" "apt-get" "$preset" "$indent"
    rc=$? && [[ $rc -eq 0 ]] && had_updates=true
  fi

  for mgr in pipx npm go cargo vscode; do
    _update_package_manager "$mgr" "$mgr" "$preset" "$indent"
    rc=$? && [[ $rc -eq 0 ]] && had_updates=true
  done

  [[ $had_updates == true ]] && return 0
  return 100
}

update_preset_with_dependencies() {
  local preset="$1" indent="$2"
  local file="${MEOW}/presets/${preset}.yaml"
  local child_indent=$((indent + 1))

  _check_preset_already_updated "$preset" "$indent" && return 100
  _validate_preset_file "$file" "$indent" || return 1

  step_header "$indent" "Updating preset: $preset"
  _update_preset_dependencies "$preset" "$file" "$child_indent"

  update_preset_packages "$preset" "$child_indent"
  rc=$?
  [[ $rc -eq 1 ]] && return 1

  local syms
  syms=$(yq eval '.symlinks[]?' "$file" 2>/dev/null)
  [[ -n "$syms" && "$syms" != "null" ]] &&
    while IFS= read -r c; do setup_symlinks "$c" "$child_indent"; done < <(printf '%s\n' "$syms")

  local script
  script=$(yq eval '.script?' "$file" 2>/dev/null)
  [[ -n "$script" && "$script" != "null" ]] &&
    execute_preset_script "$script" "$preset" "$child_indent"

  UPDATED_PRESETS+="|$preset|"
  if [[ $rc -eq 0 ]]; then
    success_tick_msg "$indent" "Preset '$preset' updated successfully"
  else
    success_tick_msg "$indent" "Preset '$preset' is up-to-date"
  fi
  return $rc
}

_process_presets() {
  local list="$1" indent="$2" pcount="$3" scount="$4" fcount="$5" ucount="$6"
  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue
    eval "$pcount=\$((\$$pcount + 1))"
    update_preset_with_dependencies "$preset" $((indent + 1))
    rc=$?
    if [[ $rc -eq 0 ]]; then
      eval "$scount=\$((\$$scount + 1))"
    elif [[ $rc -eq 100 ]]; then
      eval "$ucount=\$((\$$ucount + 1))"
    else eval "$fcount=\$((\$$fcount + 1))"; fi
  done < <(printf '%s\n' "$list")
}

_validate_installed_presets() {
  local ips="$1" indent="$2"
  [[ -n "$ips" ]] || {
    indented_warning "$indent" "No installed presets"
    return 1
  }
}

_report_update_results() {
  local indent="$1" pc="$2" su="$3" fa="$4" up="$5"
  if [[ $pc -eq 0 ]]; then
    indented_warning "$indent" "No installed presets to update"
    return 1
  elif [[ $fa -eq 0 ]]; then
    if [[ $su -gt 0 ]]; then
      success_tick_msg "$indent" "Processed $pc: $su updated, $up up-to-date"
    else
      success_tick_msg "$indent" "All $up presets are already up-to-date"
    fi
  else
    indented_warning "$indent" "Processed $pc: $su updated, $up up-to-date, $fa failed"
    return 1
  fi
}

update_installed_presets() {
  local indent=0
  UPDATED_PRESETS=""
  header "$indent" "Updating all installed presets"

  _initialize_session "Initializing package manager for update"

  local installed_presets
  installed_presets=$(get_installed_presets)
  _validate_installed_presets "$installed_presets" $((indent + 1)) || return 1

  local pc=0 su=0 fa=0 up=0
  _process_presets "$installed_presets" "$indent" pc su fa up

  _finalize_session

  _report_update_results "$indent" "$pc" "$su" "$fa" "$up"
}

update_preset() {
  local preset="$1"
  header 0 "Updating preset: $preset"
  _initialize_session "Initializing package manager for update"
  update_preset_with_dependencies "$preset" 0
  _finalize_session
}
