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
# @file: lib/package/sources.sh
# @brief: Custom package source management for presets and components.
#
if [ -n "${_LIB_PACKAGE_SOURCES_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_SOURCES_SOURCED=1

MEOW_PACKAGE_SOURCES_STATE_DIR="${MEOW}/.sources"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/yaml.sh"

_ps_collect_sources_from_file() {
  local file="$1"
  local manager="$2"
  local platform="$3"
  local distro="$4"
  local version="$5"
  local codename="$6"
  local likes="$7"

  [ -f "$file" ] || return 0

  local json
  json=$(yq -o=json '.package_sources // []' "$file" 2>/dev/null || echo "[]")

  python3 - "$manager" "$platform" "$distro" "$version" "$codename" "$likes" "$json" <<'PY'
import json
import sys

manager = sys.argv[1]
platform = sys.argv[2]
distro = sys.argv[3]
version = sys.argv[4]
codename = sys.argv[5]
likes = [x for x in sys.argv[6].split(',') if x]
entries = json.loads(sys.argv[7] or "[]")

def to_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]

def matches(entry):
    match = entry.get('match') or {}
    platforms = to_list(match.get('platform'))
    if platforms and platform not in platforms:
        return False
    distros = to_list(match.get('distro'))
    if distros and distro not in distros:
        return False
    versions = to_list(match.get('version_id'))
    if versions and (not version or version not in versions):
        return False
    distro_like = to_list(match.get('distro_like'))
    if distro_like:
        if not likes:
            return False
        if not any(item in likes for item in distro_like):
            return False
    return True

def apply_template(value):
    if not value:
        return ""
    return (
        value.replace("{{VERSION_ID}}", version or "")
        .replace("{{VERSION_CODENAME}}", codename or "")
        .replace("{{DISTRO}}", distro or "")
        .replace("{{PLATFORM}}", platform or "")
    )

for entry in entries:
    if entry.get('manager') != manager:
        continue
    if not matches(entry):
        continue
    fields = [
        apply_template(entry.get('name', '')),
        apply_template(entry.get('repo', '')),
        apply_template(entry.get('repo_file', '')),
        apply_template(entry.get('key_url', '')),
        apply_template(entry.get('gpg_key', '')),
    ]
    print("\t".join(field.replace("\t", " ") for field in fields))
PY
}

meow_ps_collect_sources() {
  local component="$1"
  local manager="$2"
  local platform
  platform=$(get_platform)
  local distro="${MEOW_OS_ID:-}"
  local version="${MEOW_OS_VERSION_ID:-}"
  local codename="${MEOW_OS_VERSION_CODENAME:-}"
  local likes="${MEOW_OS_ID_LIKE// /,}"

  local output=""
  local config_file
  config_file="${MEOW}/config/package_sources.yaml"
  if [ -f "$config_file" ]; then
    output+="$(_ps_collect_sources_from_file "$config_file" "$manager" "$platform" "$distro" "$version" "$codename" "$likes")"
    output+=$'\n'
  fi

  if [ -n "$MEOW_ACTIVE_PRESET_FILE" ] && [ -f "$MEOW_ACTIVE_PRESET_FILE" ]; then
    output+="$(_ps_collect_sources_from_file "$MEOW_ACTIVE_PRESET_FILE" "$manager" "$platform" "$distro" "$version" "$codename" "$likes")"
    output+=$'\n'
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  if [ -f "$component_file" ]; then
    output+="$(_ps_collect_sources_from_file "$component_file" "$manager" "$platform" "$distro" "$version" "$codename" "$likes")"
  fi

  printf '%s' "$output"
}

_ps_slugify() {
  local value="$1"
  echo "${value,,}" | tr -c 'a-z0-9' '-'
}

_ps_record_source() {
  local component="$1"
  local slug="$2"
  shift 2
  local state_dir="${MEOW_PACKAGE_SOURCES_STATE_DIR}/${component}"
  mkdir -p "$state_dir"
  printf '%s\n' "$@" >"${state_dir}/${slug}"
}

apply_component_sources() {
  local component="$1"
  local manager="$2"
  local sources
  sources=$(meow_pm_collect_sources_for_manager "$component" "$manager")
  [ -n "$sources" ] || return 0

  while IFS=$'\t' read -r name repo repo_file key_url gpg_key; do
    [ -n "$name$repo$repo_file$key_url" ] || continue
    case "$manager" in
      apt)
        _ps_apply_apt_source "$component" "$name" "$repo" "$key_url"
        ;;
      dnf)
        _ps_apply_dnf_source "$component" "$name" "$repo_file" "$gpg_key"
        ;;
    esac
  done <<<"$sources"
}

cleanup_component_sources() {
  local component="$1"
  local state_dir="${MEOW_PACKAGE_SOURCES_STATE_DIR}/${component}"
  [ -d "$state_dir" ] || return 0

  local state_file
  for state_file in "$state_dir"/*; do
    [ -f "$state_file" ] || continue
    local manager
    manager=$(head -n1 "$state_file")
    local paths
    paths=$(tail -n +2 "$state_file")
    case "$manager" in
      apt)
        _ps_cleanup_paths $paths
        ;;
      dnf)
        _ps_cleanup_paths $paths
        ;;
    esac
    rm -f "$state_file"
  done

  rmdir "$state_dir" 2>/dev/null || true
}

_ps_cleanup_paths() {
  local path
  for path in "$@"; do
    [ -n "$path" ] || continue
    sudo rm -f "$path" >/dev/null 2>&1 || true
  done
}

_ps_apply_apt_source() {
  local component="$1"
  local name="$2"
  local repo="$3"
  local key_url="$4"
  [ -n "$repo" ] || return 0

  local slug
  slug=$(_ps_slugify "${component}-${name:-apt}")
  local list_path="/etc/apt/sources.list.d/${slug}.list"
  local key_path=""

  if [ -f "${MEOW_PACKAGE_SOURCES_STATE_DIR}/${component}/${slug}" ]; then
    return 0
  fi

  sudo mkdir -p /etc/apt/sources.list.d >/dev/null 2>&1 || true
  {
    echo "# Added by meow component ${component}"
    echo "$repo"
  } | sudo tee "$list_path" >/dev/null

  if [ -n "$key_url" ]; then
    key_path="/etc/apt/trusted.gpg.d/${slug}.gpg"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$key_url" | sudo tee "$key_path" >/dev/null
    elif command -v wget >/dev/null 2>&1; then
      wget -qO - "$key_url" | sudo tee "$key_path" >/dev/null
    fi
  fi

  _ps_record_source "$component" "$slug" "apt" "$list_path" "$key_path"
}

_ps_apply_dnf_source() {
  local component="$1"
  local name="$2"
  local repo_file="$3"
  local gpg_key="$4"
  [ -n "$repo_file" ] || return 0

  local slug
  slug=$(_ps_slugify "${component}-${name:-dnf}")
  local repo_path="/etc/yum.repos.d/${slug}.repo"

  if [ -f "${MEOW_PACKAGE_SOURCES_STATE_DIR}/${component}/${slug}" ]; then
    return 0
  fi

  sudo mkdir -p /etc/yum.repos.d >/dev/null 2>&1 || true
  printf '%s\n' "$repo_file" | sudo tee "$repo_path" >/dev/null

  if [ -n "$gpg_key" ]; then
    sudo rpm --import "$gpg_key" >/dev/null 2>&1 || true
  fi

  _ps_record_source "$component" "$slug" "dnf" "$repo_path"
}
