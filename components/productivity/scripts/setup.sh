#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

ui_action_start "$(get_static_message "productivity_configuring")"

if [[ -d "/Applications/Linear.app" ]]; then
  ui_info "$(get_static_message "productivity_configuring_linear")"

  defaults write com.linear ShowNotifications -bool true 2>/dev/null || true
fi

if [[ -d "/Applications/Notion.app" ]]; then
  ui_info "$(get_static_message "productivity_configuring_notion")"

  notion_config_dir="$HOME/Library/Application Support/Notion"
  mkdir -p "$notion_config_dir" 2>/dev/null || true

  defaults write notion.id OpenAtLogin -bool false 2>/dev/null || true
  defaults write notion.id ShowDockIcon -bool true 2>/dev/null || true
fi

if [[ -d "/Applications/Notion Calendar.app" ]]; then
  ui_info "$(get_static_message "productivity_configuring_notion_calendar")"

  defaults write com.notion.NotionCalendar StartAtLogin -bool false 2>/dev/null || true
fi

kindle_app_path="/Applications/Kindle.app"
if [[ -d "$kindle_app_path" ]]; then
  ui_info "$(get_static_message "productivity_configuring_kindle")"

  defaults write com.amazon.Kindle WhisperSyncEnabled -bool true 2>/dev/null || true
fi

ui_action_success "$(get_static_message "productivity_configured_successfully")"
