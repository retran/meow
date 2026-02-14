#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tool-installers/scripts/setup.sh
# @brief: Setup script for tool installers (mise, pipx, cargo)
# @author: Andrew Vasilyev
# @license: MIT

set -euo pipefail

# Source required libraries
MEOW="${MEOW:-$HOME/.meow}"
source "$MEOW/lib/core/ui.sh"

# Main setup function
main() {
  ui_step_header "Tool Installers (tool-installers) Setup"
  
  # Setup mise
  setup_mise
  
  # Setup pipx
  setup_pipx_directories
  
  ui_action_success "Tool installers setup completed."
}

# Setup mise configuration
setup_mise() {
  ui_action_start "Configuring mise..."
  
  # Check if mise is available
  if ! command -v mise >/dev/null 2>&1; then
    ui_warning "mise not found. Install it first via package manager."
    return 0
  fi
  
  # Create mise config directory
  local mise_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  if [ ! -d "$mise_config_dir" ]; then
    mkdir -p "$mise_config_dir"
    ui_info "Created mise config directory: $mise_config_dir"
  fi
  
  # Create global mise.toml if it doesn't exist
  local mise_config="$mise_config_dir/config.toml"
  if [ ! -f "$mise_config" ]; then
    cat > "$mise_config" << 'EOF'
# mise global configuration
# See https://mise.jdx.dev/configuration.html

[settings]
# Automatically install missing tools
auto_install = true

# Use verbose output for debugging
# verbose = true

# Disable telemetry
disable_telemetry = true

# Global tools
# Uncomment and add versions as needed
# [tools]
# python = "3.12"
# node = "20"
# go = "1.22"
EOF
    ui_info "Created mise config: $mise_config"
  else
    ui_info "mise config already exists: $mise_config"
  fi
  
  ui_action_success "mise configured successfully."
}

# Setup pipx directories
setup_pipx_directories() {
  ui_action_start "Configuring pipx directories..."
  
  local pipx_home="${PIPX_HOME:-$HOME/.local/pipx}"
  local pipx_bin_dir="${PIPX_BIN_DIR:-$HOME/.local/bin}"
  
  # Create pipx directories
  if [ ! -d "$pipx_home" ]; then
    mkdir -p "$pipx_home"
    ui_info "Created pipx home: $pipx_home"
  fi
  
  if [ ! -d "$pipx_bin_dir" ]; then
    mkdir -p "$pipx_bin_dir"
    ui_info "Created pipx bin dir: $pipx_bin_dir"
  fi
  
  ui_action_success "pipx directories configured successfully."
}

# Run main function
main "$@"
