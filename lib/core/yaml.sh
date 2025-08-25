#!/usr/bin/env bash

if [ -n "${_LIB_YAML_SOURCED:-}" ]; then
  return 0
fi
_LIB_YAML_SOURCED=1

read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  yq eval "$yaml_path" "$yaml_file" 2>/dev/null
}

read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"

  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  local result
  result=$(yq eval "$yaml_path" "$yaml_file" 2>/dev/null) || return 1

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
