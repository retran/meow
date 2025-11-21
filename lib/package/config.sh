#!/usr/bin/env bash
# MIT License
#
# (header omitted for brevity)
#
if [ -n "${_LIB_PACKAGE_CONFIG_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_CONFIG_SOURCED=1

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/yaml.sh"

: "${MEOW_ACTIVE_PRESET_FILE:=}"

MEOW_DEFAULT_PRESET_FILE="${MEOW}/presets/base/preset.yaml"

_meow_pkg_resolve_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  yq -o=json '.packages // []' "$file" 2>/dev/null
}

_meow_pkg_match_entry() {
  local json="$1"
  local platform="$2"
  local distro="$3"
  local version="$4"
  local likes="$5"

  if [ -z "$json" ] || [ "$json" = "[]" ]; then
    echo "[]"
    return
  fi

  _ensure_yq_available
  local yq_cmd
  yq_cmd=$(command -v yq)

  local result
  result="$json"

  # Platform
  result=$(echo "$result" | "$yq_cmd" -o=json --arg platform "$platform" '.[] | select(.match.platform == null or .match.platform == $platform or (.match.platform | type == "array" and .match.platform | contains([$platform])))' | "$yq_cmd" -s -o=json '.')

  # Distro
  result=$(echo "$result" | "$yq_cmd" -o=json --arg distro "$distro" '.[] | select(.match.distro == null or .match.distro == $distro or (.match.distro | type == "array" and .match.distro | contains([$distro])))' | "$yq_cmd" -s -o=json '.')

  # Version
  if [ -n "$version" ]; then
    result=$(echo "$result" | "$yq_cmd" -o=json --arg version "$version" '.[] | select(.match.version_id == null or .match.version_id == $version or (.match.version_id | type == "array" and .match.version_id | contains([$version])))' | "$yq_cmd" -s -o=json '.')
  else
    result=$(echo "$result" | "$yq_cmd" -o=json '.[] | select(.match.version_id == null)' | "$yq_cmd" -s -o=json '.')
  fi

  # Likes
  if [ -n "$likes" ]; then
    local likes_json
    likes_json="[\"$(echo "$likes" | sed 's/,/","/g')\"]"
    result=$(echo "$result" | "$yq_cmd" -o=json --argjson likes_json "$likes_json" '.[] | select(.match.distro_like == null or (([.match.distro_like] | flatten) as $dl | ($dl | .[] | select(. as $item | $likes_json | contains([$item]))) | length > 0))' | "$yq_cmd" -s -o=json '.')
  else
    result=$(echo "$result" | "$yq_cmd" -o=json '.[] | select(.match.distro_like == null)' | "$yq_cmd" -s -o=json '.')
  fi

  echo "$result"
}

_meow_pkg_merge_managers() {
  local current="$1"
  local json="$2"

  if [ -z "$json" ] || [ "$json" = "[]" ]; then
    echo "$current"
    return
  fi

  _ensure_yq_available
  local yq_cmd
  yq_cmd=$(command -v yq)

  local managers
  managers="$current"

  local includes
  includes=$(echo "$json" | "$yq_cmd" -r '.[] | .managers.include[]?' | sed '/^null$/d' | sort -u)
  for mgr in $includes; do
    if [[ ! " $managers " =~ " $mgr " ]]; then
      managers="$managers $mgr"
    fi
  done

  local excludes
  excludes=$(echo "$json" | "$yq_cmd" -r '.[] | .managers.exclude[]?' | sed '/^null$/d' | sort -u)
  local new_managers=""
  for mgr in $managers; do
    if [[ -n "$mgr" && ! " $excludes " =~ " $mgr " ]]; then
      new_managers="$new_managers $mgr"
    fi
  done
  echo "$new_managers" | sed 's/^[ ]*//;s/[ ]*$//'
}

_meow_pkg_collect_sources() {
  local file="$1"
  local manager="$2"
  local json="$3"

  if [ -z "$json" ] || [ "$json" = "[]" ]; then
    return
  fi

  _ensure_yq_available
  local yq_cmd
  yq_cmd=$(command -v yq)

  echo "$json" | "$yq_cmd" -r --arg manager "$manager" \
    '.[] \
    | .sources[]? \
    | select(.manager == $manager) \
    | [\
        .name // "",\
        .repo // "",\
        .repo_file // "",\
        .key_url // "",\
        .gpg_key // ""\
      ] \
    | map(tostring | sub("\t"; " "; "g")) \
    | @tsv
  '
}

_meow_pkg_read_stack() {
  local platform="$1"
  local distro="$2"
  local version="$3"
  local likes="$4"
  local component="$5"
  local result="[]"

  local preset_file=""
  if [ -n "$MEOW_ACTIVE_PRESET_FILE" ]; then
    preset_file="$MEOW_ACTIVE_PRESET_FILE"
  elif [ -f "$MEOW_DEFAULT_PRESET_FILE" ]; then
    preset_file="$MEOW_DEFAULT_PRESET_FILE"
  fi

  if [ -n "$preset_file" ]; then
    local preset_entries
    preset_entries=$(_meow_pkg_collect_from_preset "$preset_file")
    result=$(echo -e "$result\n$preset_entries" | yq -s -o=json 'add')
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  local json
  json=$(_meow_pkg_resolve_file "$component_file") || echo "[]"
  local matches
  matches=$(_meow_pkg_match_entry "$json" "$platform" "$distro" "$version" "$likes")
  result=$(echo -e "$result\n$matches" | yq -s -o=json 'add')

  echo "$result"
}

meow_pm_resolve_for_component() {
  local component="$1"
  local platform
  platform=$(get_platform)
  local distro="${MEOW_OS_ID:-}"
  local version="${MEOW_OS_VERSION_ID:-}"
  local likes="${MEOW_OS_ID_LIKE// /,}"
  local entries
  entries=$(_meow_pkg_read_stack "$platform" "$distro" "$version" "$likes" "$component")
  local managers=""
  managers=$(_meow_pkg_merge_managers "$managers" "$entries")
  if [ -z "$managers" ]; then
    if [ "$IS_MACOS" = "true" ]; then
      managers="homebrew mas pipx npm go cargo vscode"
    else
      managers="pipx npm go cargo vscode apt dnf apk pacman snap"
    fi
  fi
  echo "$managers"
}

meow_pm_should_use_manager() {
  local active="$1"
  local manager="$2"
  case " $active " in
    *" $manager "*) return 0 ;;
    *)
      return 1 ;;
  esac
}

meow_pm_collect_sources_for_manager() {
  local component="$1"
  local manager="$2"
  local platform
  platform=$(get_platform)
  local distro="${MEOW_OS_ID:-}"
  local version="${MEOW_OS_VERSION_ID:-}"
  local likes="${MEOW_OS_ID_LIKE// /,}"
  local entries
  entries=$(_meow_pkg_read_stack "$platform" "$distro" "$version" "$likes" "$component")
  _meow_pkg_collect_sources "$component" "$manager" "$entries"
}

_meow_pkg_collect_from_preset_recursive() {
    local preset_file="$1"
    local base_dir="$2"
    local yq_cmd="$3"
    local visited_str="$4"

    local abs_file
    abs_file=$(cd "$(dirname "$preset_file")" && pwd)/$(basename "$preset_file")

    if [[ " $visited_str " =~ " $abs_file " ]]; then
        echo "[]"
        return
    fi

    local new_visited_str="$visited_str $abs_file"

    if [ ! -f "$preset_file" ]; then
        echo "[]"
        return
    fi

    local data
    data=$("$yq_cmd" -o=json '.' "$preset_file" 2>/dev/null || echo "{}")

    local result="[]"

    local parents
    parents=$(echo "$data" | "$yq_cmd" -r '.extends[]?' 2>/dev/null)
    if [ -n "$parents" ]; then
        local parent_packages_list="[]"
        for parent in $parents; do
            local parent_file="${base_dir}/${parent}/preset.yaml"
            local parent_packages
            parent_packages=$(_meow_pkg_collect_from_preset_recursive "$parent_file" "$base_dir" "$yq_cmd" "$new_visited_str")
            parent_packages_list=$(echo -e "$parent_packages_list\n$parent_packages" | "$yq_cmd" -s -o=json 'add')
        done
        result=$(echo -e "$result\n$parent_packages_list" | "$yq_cmd" -s -o=json 'add')
    fi
    
    local packages
    packages=$(echo "$data" | "$yq_cmd" -o=json '.packages // []' 2>/dev/null)
    result=$(echo -e "$result\n$packages" | "$yq_cmd" -s -o=json 'add')

    echo "$result"
}


_meow_pkg_collect_from_preset() {
  local preset_file="$1"
  [ -f "$preset_file" ] || { echo "[]"; return; }
  _ensure_yq_available

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="$(command -v yq 2>/dev/null || true)"
  fi

  if [ -z "$yq_cmd" ]; then
    echo "[]" && return
  fi

  _meow_pkg_collect_from_preset_recursive "$preset_file" "$MEOW_PRESETS_DIR" "$yq_cmd" ""
}