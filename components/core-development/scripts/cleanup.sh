#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(get_static_message "core_dev_cleanup_running")"

if command -v git-lfs >/dev/null 2>&1; then
  ui_info "$(get_static_message "core_dev_cleaning_git_lfs_cache")"
  git lfs prune 2>/dev/null || true
fi

if [[ -d "$HOME/.config/lazygit" ]]; then
  ui_info "$(get_static_message "core_dev_cleaning_lazygit_cache")"
  rm -rf "$HOME/.config/lazygit/logs" 2>/dev/null || true
fi

if command -v gh >/dev/null 2>&1; then
  ui_info "$(get_static_message "core_dev_cleaning_gh_cache")"
  gh cache delete --all 2>/dev/null || true
fi

if [[ -d "$HOME/.task" ]]; then
  ui_info "$(get_static_message "core_dev_cleaning_task_cache")"
  rm -rf "$HOME/.task/cache" 2>/dev/null || true
fi

ui_info "$(get_static_message "core_dev_cleaning_temp_files")"
find "$HOME" -name ".DS_Store" -delete 2>/dev/null || true
find "$HOME" -name "*.orig" -delete 2>/dev/null || true
find "$HOME" -name "*.rej" -delete 2>/dev/null || true

ui_success "$(get_static_message "core_dev_cleanup_completed")"
