#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to do so, subject to the following conditions:
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
# @file: lib/package/config.sh
# @brief: Package manager configuration helpers for presets and components.
#
if [ -n "${_LIB_PACKAGE_CONFIG_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_CONFIG_SOURCED=1

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/yaml.sh"

: "${MEOW_ACTIVE_PRESET_FILE:=}"

_pm_add_unique() {
  local list="$1"
  local value="$2"
  if [ -z "$value" ]; then
    echo "$list"
    return
  fi
  case " $list " in
    *" $value "*) echo "$list" ;;
    " ") echo "$value" ;;
    "") echo "$value" ;;
    *) echo "$list $value" ;;
  esac
}

_pm_remove_value() {
  local list="$1"
  local value="$2"
  local result=""
  for item in $list; do
    if [ "$item" != "$value" ]; then
      if [ -z "$result" ]; then
        result="$item"
      else
        result="$result $item"
      fi
    fi
  done
  echo "$result"
}

_pm_append_from_file() {
  local __var_name="$1"
  local file="$2"
  local path="$3"
  [ -f "$file" ] || return 0
  local values
  values=$(read_yaml_array "$file" "$path" 2>/dev/null || echo "")
  [ -n "$values" ] || return 0
  local current value
  current="${!__var_name}"
  while IFS= read -r value; do
    [ -n "$value" ] || continue
    current=$(_pm_add_unique "$current" "$value")
  done <<<"$values"
  printf -v "$__var_name" '%s' "$current"
}

_pm_remove_from_file() {
  local __var_name="$1"
  local file="$2"
  local path="$3"
  [ -f "$file" ] || return 0
  local values
  values=$(read_yaml_array "$file" "$path" 2>/dev/null || echo "")
  [ -n "$values" ] || return 0
  local current value
  current="${!__var_name}"
  while IFS= read -r value; do
    [ -n "$value" ] || continue
    current=$(_pm_remove_value "$current" "$value")
  done <<<"$values"
  printf -v "$__var_name" '%s' "$current"
}

_pm_current_config_file() {
  local preset_file="$MEOW_ACTIVE_PRESET_FILE"
  if [ -n "$preset_file" ] && [ -f "$preset_file" ] && yaml_path_exists "$preset_file" ".package_managers"; then
    echo "$preset_file"
    return
  fi
  if [ -f "${MEOW}/config/package_managers.yaml" ]; then
    echo "${MEOW}/config/package_managers.yaml"
  else
    echo ""
  fi
}

_pm_active_selectors() {
  local token
  echo "common"
  if [ "$IS_MACOS" = "true" ]; then
    echo "macos"
    return
  fi

  echo "linux"

  if [ -n "$MEOW_OS_ID" ]; then
    echo "$MEOW_OS_ID"
  fi

  for token in $MEOW_OS_ID_LIKE; do
    [ -n "$token" ] || continue
    echo "$token"
  done
}

meow_pm_list_contains() {
  local list=" $1 "
  local needle="$2"
  case "$list" in
    *" $needle "*) return 0 ;;
    *) return 1 ;;
  esac
}

meow_pm_resolve_for_component() {
  local component="$1"
  local config_file
  config_file=$(_pm_current_config_file)
  local managers=""

  if [ -n "$config_file" ]; then
    while IFS= read -r selector; do
      [ -n "$selector" ] || continue
      _pm_append_from_file managers "$config_file" ".package_managers.${selector}[]"
    done < <(_pm_active_selectors)
  fi

  if [ -z "$managers" ]; then
    if [ "$IS_MACOS" = "true" ]; then
      managers="homebrew mas pipx npm go cargo vscode"
    else
      managers="pipx npm go cargo vscode apt dnf apk pacman snap"
    fi
  fi

  managers=$(meow_pm_apply_component_overrides "$component" "$managers")
  echo "$managers"
}

meow_pm_apply_component_overrides() {
  local component="$1"
  local managers="$2"
  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  [ -f "$component_file" ] || { echo "$managers"; return; }

  local selector
  while IFS= read -r selector; do
    [ -n "$selector" ] || continue
    _pm_append_from_file managers "$component_file" ".package_managers.include.${selector}[]"
    _pm_remove_from_file managers "$component_file" ".package_managers.exclude.${selector}[]"
  done < <(_pm_active_selectors)

  echo "$managers"
}

meow_pm_should_use_manager() {
  local manager_list="$1"
  local manager="$2"
  meow_pm_list_contains "$manager_list" "$manager"
}
