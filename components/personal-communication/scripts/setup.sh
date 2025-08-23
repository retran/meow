#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

ui_action_start "$(get_static_message "personal_comm_configuring")"

if [[ -d "/Applications/Discord.app" ]]; then
  ui_info "$(get_static_message "personal_comm_configuring_discord")"

  discord_config_dir="$HOME/Library/Application Support/discord"
  mkdir -p "$discord_config_dir" 2>/dev/null || true

  if [[ -f "$discord_config_dir/settings.json" ]]; then
    python3 -c "
import json
import os
settings_file = '$discord_config_dir/settings.json'
if os.path.exists(settings_file):
    with open(settings_file, 'r') as f:
        settings = json.load(f)
    settings.update({
        'MINIMIZE_TO_TRAY': True,
        'START_MINIMIZED': True,
        'OPEN_ON_STARTUP': False
    })
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
" 2>/dev/null || true
  fi
fi

if [[ -d "/Applications/Telegram.app" ]]; then
  ui_info "$(get_static_message "personal_comm_configuring_telegram")"

  defaults write com.tdesktop.Telegram StartInTray -bool true 2>/dev/null || true
fi

if [[ -d "/Applications/WhatsApp.app" ]]; then
  ui_info "$(get_static_message "personal_comm_configuring_whatsapp")"

  defaults write WhatsApp KeepAlive -bool true 2>/dev/null || true
fi

ui_info "$(get_static_message "personal_comm_configuring_notifications")"

ui_action_success "$(get_static_message "personal_comm_configured_successfully")"
