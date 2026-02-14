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
# @file: lib/package/pipx.sh
# @brief: pipx utilities for isolated Python application installation and management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_PIPX_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_PIPX_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

_cache_installed_pipx_packages() {
  local cache_var="_PIPX_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed pipx packages..."
    local output
    output=$(pipx list --short 2>/dev/null | awk '{print $1}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached pipx packages."
  fi
}

is_pipx_package_installed() {
  _cache_installed_pipx_packages
  is_package_installed "pipx" "$1"
}

setup_pipx() {
  ui_step_header "Setting up pipx"

  if is_dry_run; then
    if ! command -v pipx >/dev/null 2>&1; then
      dry_run_ui_info "pipx not found. Setup would fail."
    else
      dry_run_ui_info "pipx already available. No setup needed."
    fi
    return 0
  fi

  # Add mise shims to PATH if mise is available but pipx/python is not
  if ! command -v pipx >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/python" ]; then
      export PATH="$mise_shims_dir:$PATH"
      ui_verbose_info "Added mise shims to PATH for pipx access."
    fi
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    ui_action_error "pipx not found. Please install pipx."
    return 1
  fi
  ui_action_success "pipx is available."
}

install_pipx_packages() {
  # Add mise shims to PATH if mise is available but pipx/python is not in PATH
  if ! command -v pipx >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    local mise_shims_dir="$HOME/.local/share/mise/shims"
    if [ -d "$mise_shims_dir" ] && [ -f "$mise_shims_dir/python" ]; then
      export PATH="$mise_shims_dir:$PATH"
    fi
  fi
  
  install_packages_generic "$1" "pipx" "pipx install" "is_pipx_package_installed"
}

update_pipx_packages() {
  local component="$1"
  local manager_name="pipx"
  local manager_display_name="Pipx"
  
  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  if [ ! -f "$package_file" ]; then
    return 0
  fi

  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi
    if is_pipx_package_installed "$package_name"; then
      ((total_packages++)) || true
    fi
  done <"$package_file"

  if [ "$total_packages" -eq 0 ]; then
    return 0
  fi

  local updated_count=0 up_to_date_count=0 failed_count=0
  local deduplicated_count=0 not_installed_count=0 reinstalled_count=0

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi

    if _package_update_cache_contains "$manager_name" "$package_name"; then
      ((deduplicated_count++)) || true
      if [ "$MEOW_VERBOSE" = "true" ]; then
        ui_verbose_info "$(_f "%s %s already updated earlier in this session, skipping duplicate request." "$manager_display_name" "$package_name")"
      fi
      continue
    fi

    if is_pipx_package_installed "$package_name"; then
      local update_output
      local temp_file
      temp_file=$(mktemp) || {
        ui_action_error "$(_f "Failed to create temporary file for update check.")"
        return 1
      }

      if [ "$MEOW_VERBOSE" = "true" ]; then
        ui_verbose_action_start "$(_f "Updating %s %s..." "$manager_display_name" "$package_name")"
        pipx upgrade "$package_name" >"$temp_file" 2>&1
        local exit_code=$?
      else
        (pipx upgrade "$package_name" >"$temp_file" 2>&1) &
        local cmd_pid=$!
        
        local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        local spinner_color="${YELLOW:-$(tput setaf 3 2>/dev/null || echo '')}"
        local reset_color="${RESET:-$(tput sgr0 2>/dev/null || echo '')}"
        
        while kill -0 "$cmd_pid" 2>/dev/null; do
          local char="${spinner_chars:$((i % ${#spinner_chars})):1}"
          printf "\r%b%s%b Updating %s %s" "$spinner_color" "$char" "$reset_color" "$manager_display_name" "$package_name"
          sleep 0.1
          i=$((i + 1))
        done
        
        wait "$cmd_pid" 2>/dev/null || true
        local exit_code=$?
        printf "\r%s" "$(tput el 2>/dev/null || printf '%*s' 80 '')"
      fi

      update_output=$(cat "$temp_file" 2>/dev/null || echo "")
      rm -f "$temp_file" || true

      if [ $exit_code -eq 0 ]; then
        if echo "$update_output" | grep -q "is already at latest version"; then
          ui_verbose_action_success "$(_f "%s %s is already up-to-date." "$manager_display_name" "$package_name")"
          ((up_to_date_count++)) || true
        else
          ui_verbose_action_success "$(_f "Successfully updated %s %s." "$manager_display_name" "$package_name")"
          ((updated_count++)) || true
        fi
        _package_update_cache_add "$manager_name" "$package_name"
      else
        # Check if it's a broken venv (missing pip module)
        if echo "$update_output" | grep -q "No module named pip"; then
          ui_action_warning "$(_f "%s %s has broken environment, reinstalling..." "$manager_display_name" "$package_name")"
          
          if [ "$MEOW_VERBOSE" = "true" ]; then
            if pipx reinstall "$package_name"; then
              ui_action_success "$(_f "Successfully reinstalled %s %s." "$manager_display_name" "$package_name")"
              ((reinstalled_count++)) || true
              _package_update_cache_add "$manager_name" "$package_name"
            else
              ui_action_error "$(_f "Failed to reinstall %s %s!" "$manager_display_name" "$package_name")"
              ((failed_count++)) || true
              _package_update_cache_add "$manager_name" "$package_name"
            fi
          else
            if ui_silent_spinner "$(_f "Reinstalling %s %s" "$manager_display_name" "$package_name")" pipx reinstall "$package_name"; then
              ((reinstalled_count++)) || true
              _package_update_cache_add "$manager_name" "$package_name"
            else
              ui_action_error "$(_f "Failed to reinstall %s %s!" "$manager_display_name" "$package_name")"
              ((failed_count++)) || true
              _package_update_cache_add "$manager_name" "$package_name"
            fi
          fi
        else
          ui_action_error "$(_f "Failed to update %s %s!" "$manager_display_name" "$package_name")"
          ((failed_count++)) || true
          _package_update_cache_add "$manager_name" "$package_name"
        fi
      fi
    else
      ui_action_warning "$(_f "Package %s %s not installed, skipping update." "$manager_display_name" "$package_name")"
      ((not_installed_count++)) || true
      _package_update_cache_add "$manager_name" "$package_name"
    fi
  done <"$package_file"

  local dedup_suffix=""
  if [ "$deduplicated_count" -gt 0 ]; then
    dedup_suffix="$(_f ", %d deduplicated" "$deduplicated_count")"
  fi

  if [ "$not_installed_count" -gt 0 ]; then
    dedup_suffix="$dedup_suffix$(_f ", %d not installed" "$not_installed_count")"
  fi

  if [ "$reinstalled_count" -gt 0 ]; then
    dedup_suffix="$dedup_suffix$(_f ", %d reinstalled" "$reinstalled_count")"
  fi

  if [ "$failed_count" -eq 0 ]; then
    if [ "$updated_count" -gt 0 ] || [ "$reinstalled_count" -gt 0 ]; then
      ui_indent "$(_f "%s: ✓ %d updated, %d up-to-date%s" "Pipx" "$((updated_count + reinstalled_count))" "$up_to_date_count" "$dedup_suffix")"
      return 0
    else
      ui_indent "$(_f "%s: ✓ All %d packages up-to-date%s" "Pipx" "$up_to_date_count" "$dedup_suffix")"
      return 0
    fi
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d updated, %d up-to-date%s" "Pipx" "$failed_count" "$((updated_count + reinstalled_count))" "$up_to_date_count" "$dedup_suffix")"
    return 1
  fi
}

uninstall_pipx_packages() {
  uninstall_packages_generic "$1" "pipx" "pipx uninstall" "is_pipx_package_installed"
}

cleanup_pipx() {
  if is_dry_run; then
    dry_run_ui_info "pipx cleanup would be skipped (no operation needed)."
    return 0
  fi

  if [ "${MEOW_VERBOSE:-}" = "true" ]; then
    ui_step_header "Cleaning pipx (no operation)"
    ui_action_success "pipx cleanup skipped."
  else
    ui_action_success "pipx cleanup skipped."
  fi
}
