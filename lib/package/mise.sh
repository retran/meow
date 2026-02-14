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
# @file: lib/package/mise.sh
# @brief: mise utilities for polyglot development tool version management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_PACKAGE_MISE_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_MISE_SOURCED=1

source "${MEOW}/lib/package/common.sh"
source "${MEOW}/lib/core/dry_run.sh"

# Cache installed mise tools
_cache_installed_mise_tools() {
  local cache_var="_MISE_INSTALLED_TOOLS"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "Caching installed mise tools..."
    local output
    # Get list of installed tools in format "tool@version"
    output=$(mise ls --installed 2>/dev/null | awk '{print $1"@"$2}' || true)
    eval "$cache_var=\"\$output\""
    ui_verbose_action_success "Successfully cached mise tools."
  fi
}

# Check if a mise tool@version is installed
is_mise_tool_installed() {
  local tool_spec="$1"
  _cache_installed_mise_tools
  
  # Handle both "tool" and "tool@version" formats
  if [[ "$tool_spec" == *"@"* ]]; then
    # Exact version match
    is_package_installed "mise" "$tool_spec"
  else
    # Check if any version of tool is installed
    local tool_name="$tool_spec"
    echo "$_MISE_INSTALLED_TOOLS" | grep -q "^${tool_name}@"
  fi
}

# Setup mise
setup_mise() {
  ui_step_header "Setting up mise"

  if is_dry_run; then
    if ! command -v mise >/dev/null 2>&1; then
      dry_run_ui_info "mise not found. Setup would fail."
    else
      dry_run_ui_info "mise already available. No setup needed."
    fi
    return 0
  fi

  if ! command -v mise >/dev/null 2>&1; then
    ui_action_error "mise not found. Please install mise."
    return 1
  fi
  
  ui_action_success "mise is available."
}

# Install mise tools from a package list file
# Format: tool@version or just tool (installs latest)
# Example mise.list:
#   python@3.12
#   node@20
#   go
install_mise_packages() {
  local component="$1"
  local manager_name="mise"
  local list_file="${MEOW}/components/${component}/packages/mise.list"

  if [ ! -f "$list_file" ]; then
    return 0
  fi

  ui_step_header "$(printf "Installing %s packages for '%s'" "$(ui_format_package_manager_name "$manager_name")" "$component")"

  if is_dry_run; then
    dry_run_ui_info "Would install mise packages from: $list_file"
    return 0
  fi

  local installed_count=0
  local already_present_count=0
  local failed_count=0

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    local tool_spec
    tool_spec=$(echo "$line" | xargs)

    # Check if already installed
    if is_mise_tool_installed "$tool_spec"; then
      ui_action_success "$(printf "%-40s %s" "$tool_spec" "✓ already present")"
      ((already_present_count++))
      continue
    fi

    # Install the tool
    ui_action_start "Installing $tool_spec..."
    if mise install "$tool_spec" >/dev/null 2>&1; then
      ui_action_success "$(printf "%-40s %s" "$tool_spec" "✓ installed")"
      ((installed_count++))
    else
      ui_action_error "$(printf "%-40s %s" "$tool_spec" "✗ failed")"
      ((failed_count++))
    fi
  done < "$list_file"

  # Summary
  ui_action_info "$(printf "mise: %d installed, %d already present" "$installed_count" "$already_present_count")"
  
  if [ $failed_count -gt 0 ]; then
    ui_action_warning "$(printf "mise: %d failed" "$failed_count")"
  fi

  # Clear cache after installation
  unset _MISE_INSTALLED_TOOLS
}

# Update mise tools for a component
update_mise_packages() {
  local component="$1"
  local manager_name="mise"
  local list_file="${MEOW}/components/${component}/packages/mise.list"

  if [ ! -f "$list_file" ]; then
    return 0
  fi

  ui_step_header "$(printf "Updating %s packages for '%s'" "$(ui_format_package_manager_name "$manager_name")" "$component")"

  if is_dry_run; then
    dry_run_ui_info "Would update mise packages from: $list_file"
    return 0
  fi

  local updated_count=0
  local up_to_date_count=0
  local failed_count=0

  # Track which tools we've already processed
  local processed_tools=""

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    local tool_spec
    tool_spec=$(echo "$line" | xargs)
    
    # Extract tool name (before @)
    local tool_name="${tool_spec%%@*}"
    
    # Skip if we've already processed this tool
    if [[ " $processed_tools " == *" $tool_name "* ]]; then
      continue
    fi
    processed_tools="$processed_tools $tool_name "

    # Check if tool is installed
    if ! is_mise_tool_installed "$tool_name"; then
      ui_action_warning "$(printf "%-40s %s" "$tool_spec" "not installed, skipping update")"
      continue
    fi

    # Update the tool
    ui_action_start "Updating $tool_name..."
    if mise upgrade "$tool_name" >/dev/null 2>&1; then
      ui_action_success "$(printf "%-40s %s" "$tool_name" "✓ updated")"
      ((updated_count++))
    else
      # mise upgrade returns non-zero if already up-to-date
      ui_action_success "$(printf "%-40s %s" "$tool_name" "✓ up-to-date")"
      ((up_to_date_count++))
    fi
  done < "$list_file"

  # Summary
  ui_action_info "$(printf "mise: %d updated, %d up-to-date" "$updated_count" "$up_to_date_count")"
  
  if [ $failed_count -gt 0 ]; then
    ui_action_warning "$(printf "mise: %d failed" "$failed_count")"
  fi

  # Clear cache after updates
  unset _MISE_INSTALLED_TOOLS
}

# Uninstall mise tools for a component
uninstall_mise_packages() {
  local component="$1"
  local manager_name="mise"
  local list_file="${MEOW}/components/${component}/packages/mise.list"

  if [ ! -f "$list_file" ]; then
    return 0
  fi

  ui_step_header "$(printf "Uninstalling %s packages for '%s'" "$(ui_format_package_manager_name "$manager_name")" "$component")"

  if is_dry_run; then
    dry_run_ui_info "Would uninstall mise packages from: $list_file"
    return 0
  fi

  local uninstalled_count=0
  local not_installed_count=0
  local failed_count=0

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    local tool_spec
    tool_spec=$(echo "$line" | xargs)
    
    # Extract tool name (before @)
    local tool_name="${tool_spec%%@*}"

    # Check if tool is installed
    if ! is_mise_tool_installed "$tool_name"; then
      ui_action_warning "$(printf "%-40s %s" "$tool_name" "not installed")"
      ((not_installed_count++))
      continue
    fi

    # Uninstall all versions of the tool
    ui_action_start "Uninstalling $tool_name..."
    if mise uninstall "$tool_name" --all >/dev/null 2>&1; then
      ui_action_success "$(printf "%-40s %s" "$tool_name" "✓ uninstalled")"
      ((uninstalled_count++))
    else
      ui_action_error "$(printf "%-40s %s" "$tool_name" "✗ failed")"
      ((failed_count++))
    fi
  done < "$list_file"

  # Summary
  ui_action_info "$(printf "mise: %d uninstalled" "$uninstalled_count")"
  
  if [ $not_installed_count -gt 0 ]; then
    ui_action_info "$(printf "mise: %d not installed" "$not_installed_count")"
  fi
  
  if [ $failed_count -gt 0 ]; then
    ui_action_warning "$(printf "mise: %d failed" "$failed_count")"
  fi

  # Clear cache after uninstallation
  unset _MISE_INSTALLED_TOOLS
}

# Cleanup mise (prune unused versions, clear cache)
cleanup_mise() {
  ui_step_header "Cleaning up mise"

  if is_dry_run; then
    dry_run_ui_info "Would prune unused mise tool versions"
    dry_run_ui_info "Would clear mise cache"
    return 0
  fi

  if ! command -v mise >/dev/null 2>&1; then
    ui_action_warning "mise not found. Skipping cleanup."
    return 0
  fi

  ui_action_start "Pruning unused tool versions..."
  if mise prune --yes >/dev/null 2>&1; then
    ui_action_success "Pruned unused tool versions."
  else
    ui_action_warning "Failed to prune tool versions."
  fi

  ui_action_start "Clearing mise cache..."
  if mise cache clear >/dev/null 2>&1; then
    ui_action_success "Cleared mise cache."
  else
    ui_action_warning "Failed to clear mise cache."
  fi

  # Clear our cache
  unset _MISE_INSTALLED_TOOLS
}
