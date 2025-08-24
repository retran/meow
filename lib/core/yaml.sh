#!/usr/bin/env bash

if [[ -n "${_LIB_YAML_SOURCED:-}" ]]; then
  return 0
fi
_LIB_YAML_SOURCED=1

# Ensure script exits on error, unset variables, and pipeline failures.

# Read a single YAML value from a file
read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  # yq eval can return a non-zero exit status if the path is invalid or file is malformed.
  # With set -e, this will cause the script to exit.
  # If yq returns 'null' or an empty string for a valid path, its exit status is 0,
  # and the caller is expected to handle the value.
  yq eval "$yaml_path" "$yaml_file" 2>/dev/null
}

# Read a YAML array and return items line by line
read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local result
  # Capture yq output and explicitly check its exit status.
  # This makes the function return 1 if yq itself fails, not just if set -e is active.
  result=$(yq eval "$yaml_path" "$yaml_file" 2>/dev/null) || return 1

  # Check if the result is empty or the string "null".
  # Use '=' for string literal comparison, compatible with Bash 3.2.
  if [[ -z "$result" || "$result" = "null" ]]; then
    return 1
  fi
  printf '%s\n' "$result"
}

# Process each item in a YAML array with a callback function
process_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"
  local callback="$3"
  shift 3 # Shift past yaml_file, yaml_path, and callback

  local array_content
  # If read_yaml_array returns 1 (e.g., file not found, path doesn't exist, array is empty),
  # we return 0 from this function, indicating no items to process, which is not an error.
  array_content=$(read_yaml_array "$yaml_file" "$yaml_path") || return 0

  while IFS= read -r item; do
    # Check if the item is non-empty and not the string "null".
    # Use '=' for string literal comparison, compatible with Bash 3.2.
    if [[ -n "$item" && "$item" != "null" ]]; then
      "$callback" "$item" "$@"
    fi
  done < <(printf '%s\n' "$array_content") # Process substitution for multiline string.
}

# Check if a YAML path exists and has a non-null value
yaml_path_exists() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local value
  # read_yaml_value prints the value to stdout. Capture it.
  # Its exit status reflects yq's error, if any, which set -e would catch.
  value=$(read_yaml_value "$yaml_file" "$yaml_path")

  # The return status of this function is determined by the last command.
  # Check if the captured value is non-empty and not the string "null".
  # Use '=' for string literal comparison, compatible with Bash 3.2.
  [[ -n "$value" && "$value" != "null" ]]
}
