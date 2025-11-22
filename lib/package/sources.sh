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
MEOW_APT_UPDATED=${MEOW_APT_UPDATED:-0}

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
  json=$(yq eval -o=json '.package_sources // []' "$file" 2>/dev/null || echo "[]")

  if [ -z "$json" ] || [ "$json" = "[]" ]; then
    return
  fi

  _ensure_yq_available
  local yq_cmd
  yq_cmd=$(command -v yq)

  # Matching logic
  local result
  result="$json"

  # Manager filter
  result=$(echo "$result" | manager="$manager" "$yq_cmd" eval -o=json '.[] | select(.manager == strenv(manager))' | "$yq_cmd" eval -s -o=json '.')

  # Platform
  result=$(echo "$result" | platform="$platform" "$yq_cmd" eval -o=json '.[] | select(.match.platform == null or .match.platform == strenv(platform) or (.match.platform | tag == "!!seq" and .match.platform | contains([strenv(platform)])))' | "$yq_cmd" eval -s -o=json '.')

  # Distro
  result=$(echo "$result" | distro="$distro" "$yq_cmd" eval -o=json '.[] | select(.match.distro == null or .match.distro == strenv(distro) or (.match.distro | tag == "!!seq" and .match.distro | contains([strenv(distro)])))' | "$yq_cmd" eval -s -o=json '.')

  # Version
  if [ -n "$version" ]; then
    result=$(echo "$result" | version="$version" "$yq_cmd" eval -o=json '.[] | select(.match.version_id == null or .match.version_id == strenv(version) or (.match.version_id | tag == "!!seq" and .match.version_id | contains([strenv(version)])))' | "$yq_cmd" eval -s -o=json '.')
  else
    result=$(echo "$result" | "$yq_cmd" eval -o=json '.[] | select(.match.version_id == null)' | "$yq_cmd" eval -s -o=json '.')
  fi

  # Likes
  if [ -n "$likes" ]; then
    local likes_filter=""
    local IFS=','
    for like in $likes; do
        if [ -n "$likes_filter" ]; then
            likes_filter="$likes_filter or "
        fi
        likes_filter="${likes_filter}(.match.distro_like == \"$like\" or (.match.distro_like | tag == \"!!seq\" and .match.distro_like | contains([\"$like\"])))"
    done

    result=$(echo "$result" | "$yq_cmd" eval -o=json ".[] | select(.match.distro_like == null or $likes_filter)" | "$yq_cmd" eval -s -o=json '.')
  else
    result=$(echo "$result" | "$yq_cmd" eval -o=json '.[] | select(.match.distro_like == null)' | "$yq_cmd" eval -s -o=json '.')
  fi

  # Templating and output
  echo "$result" | version="${version:-}" codename="${codename:-}" distro="${distro:-}" platform="${platform:-}" "$yq_cmd" -r \
    '
    .[]
    | [
        (if .name then .name else "" end),
        (if .repo then .repo else "" end),
        (if .repo_file then .repo_file else "" end),
        (if .key_url then .key_url else "" end),
        (if .gpg_key then .gpg_key else "" end)
      ]
    | map(
        tostring
        | sub("{{VERSION_ID}}"; strenv(version))
        | sub("{{VERSION_CODENAME}}"; strenv(codename))
        | sub("{{DISTRO}}"; strenv(distro))
        | sub("{{PLATFORM}}"; strenv(platform))
        | sub("\t"; " ")
      )
    | @tsv
    '
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
  sources=$(meow_ps_collect_sources "$component" "$manager")
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

  local signed_by_path=""
  if [[ "$repo" =~ signed-by=([^][:space:]]+) ]]; then
    signed_by_path="${BASH_REMATCH[1]}"
  fi

  local key_path_default="/usr/share/keyrings/${slug}.gpg"
  local key_path="${signed_by_path:-$key_path_default}"

  local state_dir="${MEOW_PACKAGE_SOURCES_STATE_DIR}/${component}"
  local state_file="${state_dir}/${slug}"
  if [ -f "$state_file" ]; then
    local idx=0
    local recorded_manager=""
    local recorded_paths=()
    while IFS= read -r line; do
      if [ $idx -eq 0 ]; then
        recorded_manager="$line"
      else
        if [ -n "$line" ]; then
          recorded_paths+=("$line")
        fi
      fi
      idx=$((idx + 1))
    done <"$state_file"

    if [ "$recorded_manager" = "apt" ] && [ ${#recorded_paths[@]} -gt 0 ]; then
      _ps_cleanup_paths "${recorded_paths[@]}"
    fi
    rm -f "$state_file"
  fi

  sudo mkdir -p /etc/apt/sources.list.d >/dev/null 2>&1 || true
  {
    echo "# Added by meow component ${component}"
    echo "$repo"
  } | sudo tee "$list_path" >/dev/null

  local key_installed="false"
  if [ -n "$key_url" ]; then
    local tmp_key=""
    tmp_key=$(mktemp 2>/dev/null) || true
    if [ -n "$tmp_key" ]; then
      local downloaded="false"
      if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$key_url" -o "$tmp_key"; then
          downloaded="true"
        fi
      elif command -v wget >/dev/null 2>&1; then
        if wget -qO "$tmp_key" "$key_url"; then
          downloaded="true"
        fi
      fi

      if [ "$downloaded" = "true" ] && [ -s "$tmp_key" ]; then
        local key_dir
        key_dir=$(dirname "$key_path")
        sudo mkdir -p "$key_dir" >/dev/null 2>&1 || true
        if command -v gpg >/dev/null 2>&1; then
          local tmp_key_bin=""
          tmp_key_bin=$(mktemp 2>/dev/null) || true
          if [ -n "$tmp_key_bin" ]; then
            if gpg --batch --yes --dearmor -o "$tmp_key_bin" "$tmp_key" >/dev/null 2>&1; then
              if sudo install -m 0644 "$tmp_key_bin" "$key_path" >/dev/null 2>&1; then
                key_installed="true"
              fi
            fi
            rm -f "$tmp_key_bin"
          fi
        fi

        if [ "$key_installed" != "true" ]; then
          sudo rm -f "$key_path" >/dev/null 2>&1 || true
        fi
      fi

      rm -f "$tmp_key"
    fi

    if [ "$key_installed" != "true" ]; then
      key_path=""
      sudo rm -f "$list_path" >/dev/null 2>&1 || true
      return 1
    fi
  fi

  _ps_record_source "$component" "$slug" "apt" "$list_path" "$key_path"
  MEOW_APT_SOURCES_CHANGED=1
  MEOW_APT_UPDATED=0
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
