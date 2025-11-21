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
# @brief: YAML parsing and manipulation utilities using pure POSIX shell.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_YAML_SOURCED:-}" ]; then
  return 0
fi
_LIB_YAML_SOURCED=1

# Helper function to strip leading/trailing whitespace
_yaml_trim() {
  local var="$1"
  # Remove leading whitespace
  var="${var#"${var%%[![:space:]]*}"}"
  # Remove trailing whitespace
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

# Helper function to remove quotes from a value
_yaml_unquote() {
  local var="$1"
  # Remove surrounding double quotes
  if [ "${var#\"}" != "$var" ] && [ "${var%\"}" != "$var" ]; then
    var="${var#\"}"
    var="${var%\"}"
  fi
  # Remove surrounding single quotes
  if [ "${var#\'}" != "$var" ] && [ "${var%\'}" != "$var" ]; then
    var="${var#\'}"
    var="${var%\'}"
  fi
  printf '%s' "$var"
}

# Parse scalar value from YAML file
# Args: yaml_file key_path
_parse_yaml_value() {
  local yaml_file="$1"
  local key_path="$2"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  # Remove leading dot if present
  key_path="${key_path#.}"
  
  # Handle nested paths (e.g., "parent.child")
  if echo "$key_path" | grep -q '\.'; then
    _parse_nested_yaml_value "$yaml_file" "$key_path"
    return $?
  fi
  
  # Simple key lookup
  local result=""
  local in_value=0
  local found=0
  
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip YAML document separator
    if [ "$line" = "---" ]; then
      continue
    fi
    
    # Remove inline comments (but be careful with colons in values)
    local clean_line="$line"
    if echo "$line" | grep -q '^[^:]*:[^#]*#'; then
      clean_line=$(echo "$line" | sed 's/#.*$//')
    elif echo "$line" | grep -q '^[[:space:]]*#'; then
      # Full line comment
      continue
    fi
    
    # Check if this line starts with our key
    if echo "$clean_line" | grep -q "^${key_path}:"; then
      # Extract value after the colon
      result=$(echo "$clean_line" | sed "s/^${key_path}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
      result=$(_yaml_unquote "$result")
      found=1
      break
    fi
  done < "$yaml_file"
  
  if [ "$found" -eq 1 ]; then
    # Return empty string if result is empty (not failure)
    printf '%s' "$result"
    return 0
  fi
  
  # Key not found - return failure but no output
  return 1
}

# Parse nested YAML value (e.g., "parent.child.grandchild")
# Args: yaml_file key_path
_parse_nested_yaml_value() {
  local yaml_file="$1"
  local key_path="$2"
  
  # Split the path into components
  local IFS='.'
  local -a path_parts
  read -ra path_parts <<< "$key_path"
  
  local current_level=0
  local target_level=${#path_parts[@]}
  local in_target=0
  local result=""
  local found=0
  
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and document separators
    if echo "$line" | grep -q '^[[:space:]]*#' || [ "$line" = "---" ]; then
      continue
    fi
    
    # Skip empty lines
    if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
      continue
    fi
    
    # Calculate indentation level
    local indent=0
    if [ -n "$line" ]; then
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      indent=$(( ${#line} - ${#trimmed} ))
    fi
    local level=$(( indent / 2 ))
    
    # Check if we're at the right nesting level
    if [ "$in_target" -eq 0 ]; then
      # Looking for the start of our path
      if [ "$level" -eq "$current_level" ]; then
        local key=$(echo "$line" | sed 's/:[[:space:]]*.*$//' | sed 's/^[[:space:]]*//')
        if [ "$key" = "${path_parts[$current_level]}" ]; then
          current_level=$((current_level + 1))
          if [ "$current_level" -eq "$target_level" ]; then
            # This is the final key, extract its value
            result=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            result=$(_yaml_unquote "$result")
            if [ -n "$result" ] && [ "$result" != "null" ]; then
              found=1
              break
            fi
          else
            in_target=1
          fi
        fi
      fi
    else
      # We're inside the target path
      if [ "$level" -eq "$current_level" ]; then
        local key=$(echo "$line" | sed 's/:[[:space:]]*.*$//' | sed 's/^[[:space:]]*//')
        if [ "$key" = "${path_parts[$current_level]}" ]; then
          current_level=$((current_level + 1))
          if [ "$current_level" -eq "$target_level" ]; then
            # Found the final key
            result=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/[[:space:]]*$//')
            result=$(_yaml_unquote "$result")
            if [ -n "$result" ] && [ "$result" != "null" ]; then
              found=1
              break
            fi
          fi
        fi
      elif [ "$level" -lt "$current_level" ]; then
        # We've gone back out of our target section without finding the key
        break
      fi
    fi
  done < "$yaml_file"
  
  if [ "$found" -eq 1 ]; then
    printf '%s' "$result"
    return 0
  fi
  
  return 1
}

# Parse array items from YAML file
# Args: yaml_file array_path
_parse_yaml_array() {
  local yaml_file="$1"
  local array_path="$2"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  # Remove leading dot and trailing [] if present
  array_path="${array_path#.}"
  array_path="${array_path%\[\]}"
  array_path="${array_path%\[\?\]}"
  
  # Handle nested paths (e.g., "parent.children")
  if echo "$array_path" | grep -q '\.'; then
    _parse_nested_yaml_array "$yaml_file" "$array_path"
    return $?
  fi
  
  local in_array=0
  local array_indent=-1
  local found_items=0
  
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and document separators
    if echo "$line" | grep -q '^[[:space:]]*#' || [ "$line" = "---" ]; then
      continue
    fi
    
    # Skip empty lines
    if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
      continue
    fi
    
    # Calculate indentation
    local indent=0
    if [ -n "$line" ]; then
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      indent=$(( ${#line} - ${#trimmed} ))
    fi
    
    if [ "$in_array" -eq 0 ]; then
      # Looking for array key
      if echo "$line" | grep -q "^${array_path}:" || echo "$line" | grep -q "^[[:space:]]*${array_path}:"; then
        # Check if it's an inline array
        if echo "$line" | grep -q '\[.*\]'; then
          # Inline array format: key: [item1, item2]
          local items=$(echo "$line" | sed 's/^[^:]*:[[:space:]]*\[//' | sed 's/\][[:space:]]*$//')
          if [ -n "$items" ]; then
            # Split by comma and output each item
            echo "$items" | tr ',' '\n' | while IFS= read -r item; do
              item=$(_yaml_trim "$item")
              item=$(_yaml_unquote "$item")
              if [ -n "$item" ]; then
                echo "$item"
              fi
            done
            return 0
          fi
        fi
        in_array=1
        array_indent=$indent
      fi
    else
      # We're in the array, collect items
      if echo "$line" | grep -q '^[[:space:]]*-[[:space:]]'; then
        local item_indent=0
        if [ -n "$line" ]; then
          local before_dash="${line%%-*}"
          item_indent=${#before_dash}
        fi
        
        # Check if still in our array (indentation should be greater than array key)
        if [ "$item_indent" -gt "$array_indent" ]; then
          local item=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*$//')
          item=$(_yaml_unquote "$item")
          if [ -n "$item" ]; then
            echo "$item"
            found_items=1
          fi
        else
          # Indentation decreased, we're out of the array
          break
        fi
      elif [ "$indent" -le "$array_indent" ] && echo "$line" | grep -q ':'; then
        # Hit another key at same or lower level, array ended
        break
      fi
    fi
  done < "$yaml_file"
  
  if [ "$found_items" -eq 1 ]; then
    return 0
  fi
  
  return 1
}

# Parse nested array items (e.g., "parent.children")
# Args: yaml_file array_path
_parse_nested_yaml_array() {
  local yaml_file="$1"
  local array_path="$2"
  
  # Split the path into components
  local IFS='.'
  local -a path_parts
  read -ra path_parts <<< "$array_path"
  
  local current_level=0
  local target_level=$((${#path_parts[@]} - 1))
  local array_key="${path_parts[$target_level]}"
  local in_target_section=0
  local in_array=0
  local array_indent=-1
  local found_items=0
  local -a level_indents
  
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and document separators
    if echo "$line" | grep -q '^[[:space:]]*#' || [ "$line" = "---" ]; then
      continue
    fi
    
    # Skip empty lines
    if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
      continue
    fi
    
    # Calculate indentation
    local indent=0
    if [ -n "$line" ]; then
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      indent=$(( ${#line} - ${#trimmed} ))
    fi
    
    # Navigate to the target nested level
    if [ "$in_target_section" -eq 0 ]; then
      # Track if we're at the right nesting level by comparing indents
      local key=$(echo "$line" | sed 's/:[[:space:]]*.*$//' | sed 's/^[[:space:]]*//')
      
      # Check if this is one of our path components
      if [ "$current_level" -lt "${#path_parts[@]}" ] && [ "$key" = "${path_parts[$current_level]}" ]; then
        level_indents[$current_level]=$indent
        current_level=$((current_level + 1))
        
        if [ "$current_level" -gt "$target_level" ]; then
          in_target_section=1
          in_array=1
          array_indent=$indent
        fi
      fi
    elif [ "$in_array" -eq 1 ]; then
      # We're in the target array section
      if echo "$line" | grep -q '^[[:space:]]*-[[:space:]]'; then
        local item_indent=0
        if [ -n "$line" ]; then
          local before_dash="${line%%-*}"
          item_indent=${#before_dash}
        fi
        
        # Check if still in our array
        if [ "$item_indent" -gt "$array_indent" ]; then
          local item=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*$//')
          item=$(_yaml_unquote "$item")
          if [ -n "$item" ]; then
            echo "$item"
            found_items=1
          fi
        else
          # Indentation decreased, we're out of the array
          break
        fi
      elif [ "$indent" -le "$array_indent" ] && echo "$line" | grep -q ':'; then
        # Hit another key at same or lower level, array ended
        break
      fi
    fi
  done < "$yaml_file"
  
  if [ "$found_items" -eq 1 ]; then
    return 0
  fi
  
  return 1
}

# Public API: Read scalar value from YAML
# Args: yaml_file key_path
read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  # Always return success, just empty string if not found
  _parse_yaml_value "$yaml_file" "$yaml_path" || true
}

# Public API: Read array items from YAML
# Args: yaml_file array_path
read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  local result
  result=$(_parse_yaml_array "$yaml_file" "$yaml_path")
  local status=$?
  
  if [ $status -eq 0 ] && [ -n "$result" ]; then
    printf '%s\n' "$result"
    return 0
  fi
  
  return 1
}

# Process each item in a YAML array with a callback function
# Args: yaml_file array_path callback [callback_args...]
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

# Check if a YAML path exists and has a non-empty value
# Args: yaml_file yaml_path
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

# Get the length of an array in a YAML file
# Args: yaml_file
yaml_array_length() {
  local yaml_file="$1"
  
  if [ ! -f "$yaml_file" ]; then
    echo "0"
    return 1
  fi
  
  # Count lines starting with -
  local length
  length=$(grep -c '^[[:space:]]*-[[:space:]]' "$yaml_file" 2>/dev/null || echo "0")
  
  # Validate that it's a number
  case "$length" in
    '' | *[!0-9]*) echo "0" ;;
    *) echo "$length" ;;
  esac
}

# Get a specific item from an array by index
# Args: yaml_file index [field]
yaml_array_item() {
  local yaml_file="$1"
  local index="$2"
  local field="$3"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  # Get all array items
  local items
  items=$(grep '^[[:space:]]*-[[:space:]]' "$yaml_file" | sed 's/^[[:space:]]*-[[:space:]]*//')
  
  if [ -z "$items" ]; then
    return 1
  fi
  
  # Get the item at the specified index (0-based)
  local result
  result=$(echo "$items" | sed -n "$((index + 1))p")
  
  if [ -z "$result" ]; then
    return 1
  fi
  
  result=$(_yaml_unquote "$result")
  
  # If a field is specified, try to extract it
  if [ -n "$field" ]; then
    # This is a simplified version - for complex object extraction,
    # you'd need to parse the nested structure
    echo "$result"
    return 0
  fi
  
  echo "$result"
}

# Get nested array items (e.g., .category.section[])
# Args: yaml_file category section
yaml_nested_array() {
  local yaml_file="$1"
  local category="$2"
  local section="$3"
  
  if [ ! -f "$yaml_file" ]; then
    return 1
  fi
  
  # Build the path
  local path="${category}.${section}"
  
  # Use the array parser
  local result
  result=$(_parse_yaml_array "$yaml_file" "$path")
  local status=$?
  
  if [ $status -eq 0 ] && [ -n "$result" ]; then
    echo "$result"
    return 0
  fi
  
  return 1
}
