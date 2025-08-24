#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "productivity_cleanup_running")"

if pgrep -f "Linear" >/dev/null; then
  ui_info "$(fmt "productivity_stopping_linear")"
  osascript -e 'tell application "Linear" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "Notion" >/dev/null; then
  ui_info "$(fmt "productivity_stopping_notion")"
  osascript -e 'tell application "Notion" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "Notion Calendar" >/dev/null; then
  ui_info "$(fmt "productivity_stopping_notion_calendar")"
  osascript -e 'tell application "Notion Calendar" to quit' 2>/dev/null || true
  sleep 2
fi

if pgrep -f "Kindle" >/dev/null; then
  ui_info "$(fmt "productivity_stopping_kindle")"
  osascript -e 'tell application "Kindle" to quit' 2>/dev/null || true
  sleep 2
fi

if [[ -d "$HOME/Library/Caches/com.linear" ]]; then
  ui_info "$(fmt "productivity_cleaning_linear_cache")"
  rm -rf "$HOME/Library/Caches/com.linear" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Application Support/Notion" ]]; then
  ui_info "$(fmt "productivity_cleaning_notion_cache")"
  rm -rf "$HOME/Library/Application Support/Notion/Cache" 2>/dev/null || true
  rm -rf "$HOME/Library/Application Support/Notion/logs" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/com.notion.NotionCalendar" ]]; then
  ui_info "$(fmt "productivity_cleaning_notion_calendar_cache")"
  rm -rf "$HOME/Library/Caches/com.notion.NotionCalendar" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/com.amazon.Kindle" ]]; then
  ui_info "$(fmt "productivity_cleaning_kindle_cache")"
  rm -rf "$HOME/Library/Caches/com.amazon.Kindle" 2>/dev/null || true
fi

ui_info "$(fmt "productivity_removing_login_items")"
osascript -e '
tell application "System Events"
    try
        delete login item "Linear"
    end try
    try
        delete login item "Notion"
    end try
    try
        delete login item "Notion Calendar"
    end try
end tell
' 2>/dev/null || true

ui_success "$(fmt "productivity_cleanup_completed")"
