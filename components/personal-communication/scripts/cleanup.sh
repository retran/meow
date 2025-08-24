#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "TODO: write message - personal_comm_cleanup_running"

if pgrep -f "Discord" >/dev/null; then
  ui_info "TODO: write message - personal_comm_stopping_discord"
  osascript -e 'tell application "Discord" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "Telegram" >/dev/null; then
  ui_info "TODO: write message - personal_comm_stopping_telegram"
  osascript -e 'tell application "Telegram" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "WhatsApp" >/dev/null; then
  ui_info "TODO: write message - personal_comm_stopping_whatsapp"
  osascript -e 'tell application "WhatsApp" to quit' 2>/dev/null || true
  sleep 2
fi

if [[ -d "$HOME/Library/Application Support/discord" ]]; then
  ui_info "TODO: write message - personal_comm_cleaning_discord_cache"
  rm -rf "$HOME/Library/Application Support/discord/Cache" 2>/dev/null || true
  rm -rf "$HOME/Library/Application Support/discord/logs" 2>/dev/null || true
  rm -rf "$HOME/Library/Caches/com.hnc.Discord" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Application Support/Telegram Desktop" ]]; then
  ui_info "TODO: write message - personal_comm_cleaning_telegram_cache"
  rm -rf "$HOME/Library/Application Support/Telegram Desktop/cache" 2>/dev/null || true
  rm -rf "$HOME/Library/Caches/com.tdesktop.Telegram" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/WhatsApp" ]]; then
  ui_info "TODO: write message - personal_comm_cleaning_whatsapp_cache"
  rm -rf "$HOME/Library/Caches/WhatsApp" 2>/dev/null || true
fi

ui_info "TODO: write message - personal_comm_removing_login_items"
osascript -e '
tell application "System Events"
    try
        delete login item "Discord"
    end try
    try
        delete login item "Telegram"
    end try
    try
        delete login item "WhatsApp"
    end try
end tell
' 2>/dev/null || true

ui_success "TODO: write message - personal_comm_cleanup_completed"
