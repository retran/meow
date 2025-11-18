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
# @file: lib/core/yaml.sh
# @brief: YAML parsing and manipulation utilities.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_YAML_SOURCED:-}" ]; then
  return 0
fi
_LIB_YAML_SOURCED=1

source "${MEOW}/lib/core/tools.sh"

_ensure_yq_available() {
  if [ ! -x "/usr/local/bin/yq" ] && ! command -v yq >/dev/null 2>&1; then
    ensure_yq
  fi
}

_parse_yaml_with_fallbacks() {
  local yaml_file="$1"
  local yaml_path="$2"
  local is_array="$3" # "true" for array parsing, "false" for value parsing

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi

  _ensure_yq_available

  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  local result=""

  # Method 1: yq eval
  if [ -z "$result" ]; then
    result=$("$yq_cmd" eval "$yaml_path" "$yaml_file" 2>/dev/null || true)
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "Debug: $yq_cmd eval '$yaml_path' result: '$result'" >&2
    fi
  fi

  # Method 2: yq without eval
  if [ -z "$result" ] || [ "$result" = "null" ]; then
    result=$("$yq_cmd" "$yaml_path" "$yaml_file" 2>/dev/null || true)
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "Debug: $yq_cmd '$yaml_path' result: '$result'" >&2
    fi
  fi

  # Method 3: yq with alternative path syntax
  if [ -z "$result" ] || [ "$result" = "null" ]; then
    local alt_path="$yaml_path"
    alt_path="${alt_path#.}"           # Remove leading dot
    alt_path="${alt_path//\[\]/[*]}"   # Convert [] to [*]
    alt_path="${alt_path//\[\?\]/[*]}" # Convert [?] to [*]
    result=$("$yq_cmd" r "$yaml_file" "$alt_path" 2>/dev/null || true)
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "Debug: $yq_cmd r '$alt_path' result: '$result'" >&2
    fi
  fi

  if [ "$result" = "null" ]; then
    result=""
  fi

  if [ -n "$result" ]; then
    printf '%s' "$result"
    return 0
  fi

  # Method 4: Manual parsing
  if [ -z "$result" ]; then
    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "Debug: yq did not return a value, checking manual parsing fallback" >&2
    fi

    if [ "$is_array" = "true" ]; then
      # Array parsing
      case "$yaml_path" in
        ".depends_on[]" | ".depends_on[]?" | "depends_on[]" | "depends_on[]?" | ".depends_on" | "depends_on")
          result=$(grep -A 20 '^depends_on:' "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' || true)
          ;;
        ".required[]" | ".required[]?" | "required[]" | "required[]?" | ".required" | "required")
          result=$(grep -A 20 '^required:' "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' || true)
          ;;
        ".platforms[]" | ".platforms[]?" | "platforms[]" | "platforms[]?" | ".platforms" | "platforms")
          result=$(grep -A 20 '^platforms:' "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' || true)
          ;;
        *)
          # Generic array extraction
          local key_path="${yaml_path%\[\]*}" # Remove []* suffix
          key_path="${key_path#.}"            # Remove leading dot
          result=$(grep -A 20 "^${key_path}:" "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' || true)
          ;;
      esac
    else
      # Value parsing
      case "$yaml_path" in
        ".depends_on" | "depends_on")
          # For depends_on as value, return space-separated list
          result=$(grep -A 10 '^depends_on:' "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' | tr '\n' ' ' | sed 's/ $//' || true)
          ;;
        ".description" | "description")
          result=$(grep '^description:' "$yaml_file" 2>/dev/null | sed 's/^description: *//' || true)
          ;;
        ".platforms" | "platforms")
          # For platforms as value, return space-separated list
          result=$(grep -A 10 '^platforms:' "$yaml_file" 2>/dev/null | grep '^  - ' | sed 's/^  - //' | tr '\n' ' ' | sed 's/ $//' || true)
          ;;
        *)
          # Generic value extraction
          local key="${yaml_path#.}"
          result=$(grep "^${key}:" "$yaml_file" 2>/dev/null | sed "s/^${key}: *//" || true)
          ;;
      esac
    fi

    if [ "$MEOW_VERBOSE" = "true" ]; then
      ui_verbose_info "Debug: manual parsing result: '$result'" >&2
    fi
  fi

  printf '%s' "$result"
}

read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"

  _parse_yaml_with_fallbacks "$yaml_file" "$yaml_path" "false"
}

read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi

  local result
  result=$(_parse_yaml_with_fallbacks "$yaml_file" "$yaml_path" "true")

  if [ -z "$result" ] || [ "$result" = "null" ]; then
    return 1
  fi

  printf '%s\n' "$result"
}

process_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"
  local callback="$3"
  shift 3

  local array_content
  array_content=$(read_yaml_array "$yaml_file" "$yaml_path") || return 0

  if [ -n "$array_content" ]; then
    while IFS= read -r item; do
      if [ -n "$item" ] && [ "$item" != "null" ]; then
        if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
          printf 'Processing: %s\n' "$item"
        fi
        if [ "${MEOW_DRY_RUN:-false}" != "true" ]; then
          "$callback" "$item" "$@"
        else
          if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
            printf 'DRY-RUN: Would execute: %s %s\n' "$callback" "$item"
          fi
        fi
      fi
    done < <(printf '%s\n' "$array_content")
  fi
}

yaml_path_exists() {
  local yaml_file="$1"
  local yaml_path="$2"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  local value
  value=$(read_yaml_value "$yaml_file" "$yaml_path")

  if [ -n "$value" ] && [ "$value" != "null" ]; then
    return 0
  else
    return 1
  fi
}

yaml_array_length() {
  local yaml_file="$1"

  if [ ! -f "$yaml_file" ]; then
    echo "0"
    return 1
  fi

  # Ensure yq is available
  _ensure_yq_available

  # Use the installed yq version
  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  local length
  length=$("$yq_cmd" 'length' "$yaml_file" 2>/dev/null || echo "0")

  # Validate that it's a number
  case "$length" in
    '' | *[!0-9]*) echo "0" ;;
    *) echo "$length" ;;
  esac
}

yaml_array_item() {
  local yaml_file="$1"
  local index="$2"
  local field="$3"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi

  # Ensure yq is available
  _ensure_yq_available

  # Use the installed yq version
  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  local result
  if [ -n "$field" ]; then
    result=$("$yq_cmd" ".[$index].$field" "$yaml_file" 2>/dev/null || echo "")
  else
    result=$("$yq_cmd" ".[$index]" "$yaml_file" 2>/dev/null || echo "")
  fi

  if [ -z "$result" ] || [ "$result" = "null" ]; then
    return 1
  fi

  # Remove surrounding quotes if present
  result="${result#\"}"
  result="${result%\"}"

  echo "$result"
}

yaml_nested_array() {
  local yaml_file="$1"
  local category="$2"
  local section="$3"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi

  # Ensure yq is available
  _ensure_yq_available

  # Use the installed yq version
  local yq_cmd="/usr/local/bin/yq"
  if [ ! -x "$yq_cmd" ]; then
    yq_cmd="yq"
  fi

  local result
  result=$("$yq_cmd" -r ".${category}.${section}[]" "$yaml_file" 2>/dev/null || echo "")

  if [ -z "$result" ]; then
    return 1
  fi

  echo "$result"
}
