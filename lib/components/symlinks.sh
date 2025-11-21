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
# @file: lib/components/symlinks.sh
# @brief: Component symlink setup and removal for dotfile configuration management.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/yaml.sh"

if [ -n "${_LIB_COMPONENTS_SYMLINKS_SOURCED:-}" ]; then
  return 0
fi
_LIB_COMPONENTS_SYMLINKS_SOURCED=1

source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/symlinks/symlinks.sh"

setup_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  if [ ! -d "$symlinks_dir" ]; then
    return 0
  fi

  local yaml_files=
  local item

  while IFS= read -r -d '' item; do
    yaml_files="$yaml_files"$'\n'"$item"
  done < <(find "$symlinks_dir" -name "*.yaml" -print0 2>/dev/null)

  if [ -z "$yaml_files" ]; then
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Setting up symlinks for component '%s'" "$component")"
  fi

  local had_symlinks="false"
  local success_count=0
  local error_count=0

  local yaml_file
  for yaml_file in $yaml_files; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks="true"

    if setup_component_symlinks_from_file "$component" "$symlink_name"; then
      ui_verbose_action_success "$(_f "Symlink configuration for '%s' processed successfully." "$symlink_name")"
      success_count=$((success_count + 1))
    else
      ui_action_warning "$(_f "Failed to process symlink configuration for '%s'." "$symlink_name")"
      error_count=$((error_count + 1))
    fi
  done

  if [ "$had_symlinks" = "true" ]; then
    if [ "$MEOW_VERBOSE" != "true" ]; then
      if [ "$error_count" -eq 0 ]; then
        local config_plural=""
        [ "$success_count" -gt 1 ] && config_plural="s"
        ui_indent "$(_f "Symlinks: ✓ %d configuration%s checked" "$success_count" "$config_plural")"
      else
        local error_plural=""
        [ "$error_count" -gt 1 ] && error_plural="s"
        ui_indent "$(_f "Symlinks: ✕ %d error%s, %d successful" "$error_count" "$error_plural" "$success_count")"
      fi
    else
      local total_processed=$((success_count + error_count))
      local error_plural_verbose=""
      [ "$error_count" -gt 1 ] && error_plural_verbose="s"
      if [ "$error_count" -eq 0 ]; then
        ui_action_success "$(_f "All %d symlink configurations processed successfully." "$total_processed")"
      else
        ui_warning "$(_f "Processed %d symlink configurations with %d error%s (%d successful)." "$total_processed" "$error_count" "$error_plural_verbose" "$success_count")"
      fi
    fi
  fi
}

remove_component_symlinks() {
  local component="$1"
  local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"

  if [ ! -d "$symlinks_dir" ]; then
    return 0
  fi

  local yaml_files=
  local item

  while IFS= read -r -d '' item; do
    yaml_files="$yaml_files"$'\n'"$item"
  done < <(find "$symlinks_dir" -name "*.yaml" -print0 2>/dev/null)

  if [ -z "$yaml_files" ]; then
    return 0
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_step_header "$(_f "Removing symlinks for component '%s'" "$component")"
  fi

  local had_symlinks="false"
  local success_count=0
  local error_count=0

  local yaml_file
  for yaml_file in $yaml_files; do
    local symlink_name
    symlink_name=$(basename "$yaml_file" .yaml)
    had_symlinks="true"

    if remove_component_symlinks_from_file "$component" "$symlink_name"; then
      ui_verbose_action_success "$(_f "Symlink configuration for '%s' processed successfully." "$symlink_name")"
      success_count=$((success_count + 1))
    else
      ui_action_warning "$(_f "Failed to process symlink configuration for '%s'." "$symlink_name")"
      error_count=$((error_count + 1))
    fi
  done

  if [ "$had_symlinks" = "true" ]; then
    local total_processed=$((success_count + error_count))
    local error_plural=""
    [ "$error_count" -gt 1 ] && error_plural="s"
    if [ "$error_count" -eq 0 ]; then
      ui_action_success "$(_f "All %d component symlink files processed successfully." "$total_processed")"
    else
      ui_warning "$(_f "Processed %d component symlink files with %d error%s (%d successful)." "$total_processed" "$error_count" "$error_plural" "$success_count")"
    fi
  fi
}

remove_component_symlinks_from_file() {
  local component="$1"
  local symlink_name="$2"
  local symlinks_file="${MEOW_COMPONENTS_DIR}/${component}/symlinks/${symlink_name}.yaml"

  if is_dry_run; then
    if [ -f "$symlinks_file" ]; then
      local num_symlinks
      num_symlinks=$(yaml_array_length "$symlinks_file")

      if [[ "$num_symlinks" =~ ^[0-9]+$ ]] && [ "$num_symlinks" -gt 0 ]; then
        local i=0
        while [ "$i" -lt "$num_symlinks" ]; do
          local target_path
          target_path=$(yaml_array_item "$symlinks_file" "$i" "target")

          if [ "$target_path" != "null" ] && [ -n "$target_path" ]; then
            local expanded_target
            expanded_target=$(expand_path "$target_path")
            if [ -L "$expanded_target" ]; then
              dry_run_ui_info "$(_f "Would remove symlink: %s" "$expanded_target")"
            elif [ -e "$expanded_target" ]; then
              dry_run_ui_info "$(_f "Would skip non-symlink: %s" "$expanded_target")"
            else
              dry_run_ui_info "$(_f "Would skip non-existent target: %s" "$expanded_target")"
            fi
          else
            dry_run_ui_info "$(_f "Would skip symlink entry %d in %s due to missing or empty target path." "$i" "$symlinks_file")"
          fi
          i=$((i + 1))
        done
      else
        dry_run_ui_info "$(_f "No symlinks defined or invalid content for dry-run in %s." "$symlinks_file")"
      fi
    else
      dry_run_ui_info "$(_f "Symlinks file %s not found for dry-run." "$symlinks_file")"
    fi
    return 0
  fi

  local failed_count=0
  local processed_count=0
  local restored_count=0

  if [ ! -f "$symlinks_file" ]; then
    ui_warning "$(_f "No symlinks configuration file found for '%s' at %s." "$symlink_name" "$symlinks_file")"
    return 0
  fi

  local num_symlinks
  num_symlinks=$(yaml_array_length "$symlinks_file")

  if ! [[ "$num_symlinks" =~ ^[0-9]+$ ]] || [ "$num_symlinks" -eq 0 ]; then
    ui_warning "$(_f "No symlinks defined or invalid content in %s." "$symlinks_file")"
    return 0
  fi

  local i=0
  while [ "$i" -lt "$num_symlinks" ]; do
    local target_path
    target_path=$(yaml_array_item "$symlinks_file" "$i" "target")

    if [ "$target_path" = "null" ] || [ -z "$target_path" ]; then
      ui_warning "$(_f "Missing or empty 'target' key in symlink entry %d of %s. Skipping." "$i" "$symlinks_file")"
      failed_count=$((failed_count + 1))
      i=$((i + 1))
      continue
    fi

    local expanded_target
    expanded_target=$(expand_path "$target_path")

    processed_count=$((processed_count + 1))

    if [ -L "$expanded_target" ]; then
      if rm "$expanded_target"; then
        local backup_pattern_base="$(basename "$expanded_target").backup.*"
        local backup_dir="$(dirname "$expanded_target")"
        local latest_backup=""
        local latest_mtime=0

        # Determine stat command based on OS
        local STAT_CMD
        if uname | grep -q "Darwin"; then
          STAT_CMD="stat -f %m" # macOS (BSD stat)
        else
          STAT_CMD="stat -c %Y" # Linux (GNU stat)
        fi

        local potential_backups_list=
        local backup_item

        while IFS= read -r -d '' backup_item; do
          potential_backups_list="$potential_backups_list"$'\n'"$backup_item"
        done < <(find "$backup_dir" -maxdepth 1 -type f -name "$backup_pattern_base" -print0 2>/dev/null)

        local backup_file
        for backup_file in $potential_backups_list; do
          if [ -f "$backup_file" ]; then
            local current_mtime
            current_mtime=$($STAT_CMD "$backup_file" 2>/dev/null)
            if [ -n "$current_mtime" ] && [ "$current_mtime" -gt "$latest_mtime" ]; then
              latest_mtime="$current_mtime"
              latest_backup="$backup_file"
            fi
          fi
        done

        if [ -n "$latest_backup" ]; then
          if mv "$latest_backup" "$expanded_target"; then
            ui_verbose_info "$(_f "Restored '%s' from backup." "$(basename "$expanded_target")")"
            restored_count=$((restored_count + 1))
          else
            ui_action_error "$(_f "Failed to restore backup for '%s'." "$(basename "$expanded_target")")"
            failed_count=$((failed_count + 1))
          fi
        else
          ui_verbose_info "$(_f "Removed '%s', no backup found to restore." "$(basename "$expanded_target")")"
        fi
      else
        ui_action_error "$(_f "Failed to remove symlink: %s." "$expanded_target")"
        failed_count=$((failed_count + 1))
      fi
    elif [ -e "$expanded_target" ]; then
      ui_verbose_info "$(_f "Skipping '%s': it is not a symlink, cannot remove." "$(basename "$expanded_target")")"
    else
      ui_verbose_info "$(_f "Skipping '%s': target does not exist, no action needed." "$(basename "$expanded_target")")"
    fi

    i=$((i + 1))
  done

  if [ "$failed_count" -eq 0 ]; then
    if [ "$restored_count" -gt 0 ]; then
      ui_action_success "$(_f "Processed %d symlinks successfully (%d restored from backup)." "$processed_count" "$restored_count")"
    else
      ui_action_success "$(_f "Processed %d symlinks successfully (no backups to restore)." "$processed_count")"
    fi
    return 0
  else
    ui_action_error "$(_f "Failed to process %d of %d symlinks." "$failed_count" "$processed_count")"
    return 1
  fi
}
