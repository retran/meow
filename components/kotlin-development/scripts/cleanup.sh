#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "kotlin_dev_cleanup_running")"

if pgrep -f "IntelliJ IDEA" >/dev/null; then
  ui_info "$(get_static_message "kotlin_dev_stopping_intellij")"
  osascript -e 'tell application "IntelliJ IDEA" to quit' 2>/dev/null || true
  sleep 3
fi

if [[ -d "$HOME/.gradle" ]]; then
  ui_info "$(get_static_message "kotlin_dev_cleaning_gradle_cache")"
  rm -rf "$HOME/.gradle/caches" 2>/dev/null || true
  rm -rf "$HOME/.gradle/daemon" 2>/dev/null || true
  rm -rf "$HOME/.gradle/wrapper/dists" 2>/dev/null || true
fi

if [[ -d "$HOME/.kotlin" ]]; then
  ui_info "$(get_static_message "kotlin_dev_cleaning_kotlin_cache")"
  rm -rf "$HOME/.kotlin/caches" 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Caches/JetBrains" ]]; then
  ui_info "$(get_static_message "kotlin_dev_cleaning_intellij_cache")"
  rm -rf "$HOME/Library/Caches/JetBrains/IntelliJIdea"* 2>/dev/null || true
fi

if [[ -d "$HOME/Library/Logs/JetBrains" ]]; then
  ui_info "$(get_static_message "kotlin_dev_cleaning_intellij_logs")"
  rm -rf "$HOME/Library/Logs/JetBrains/IntelliJIdea"* 2>/dev/null || true
fi

ui_success "$(get_static_message "kotlin_dev_cleanup_completed")"
