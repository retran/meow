#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

ui_action_start "TODO: write message - gaming_configuring"

if [[ -d "/Applications/Steam.app" ]]; then
  ui_info "TODO: write message - gaming_configuring_steam"

  mkdir -p "$HOME/Library/Application Support/Steam/steamapps" 2>/dev/null || true

  steam_config_dir="$HOME/Library/Application Support/Steam/config"
  if [[ -d "$steam_config_dir" ]]; then
    touch "$steam_config_dir/DialogConfig.vdf" 2>/dev/null || true
  fi
fi

if [[ -d "/Applications/GeForce NOW.app" ]]; then
  ui_info "TODO: write message - gaming_configuring_geforce_now"

  geforce_config_dir="$HOME/Library/Application Support/NVIDIA Corporation/GeForce NOW"
  if [[ -d "$geforce_config_dir" ]]; then
    touch "$geforce_config_dir/.preferences_configured" 2>/dev/null || true
  fi
fi

ui_info "TODO: write message - gaming_configuring_system_settings"

sudo sysctl -w net.inet.tcp.delayed_ack=0 2>/dev/null || true

ui_action_success "TODO: write message - gaming_configured_successfully"
