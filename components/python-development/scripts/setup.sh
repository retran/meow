#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if ! command -v python3 >/dev/null 2>&1; then
  ui_warning "$(get_static_message "python_dev_python_not_found_skip")"
  exit 0
fi

ui_action_start "$(get_static_message "python_dev_configuring")"

if command -v pyenv >/dev/null 2>&1; then
  ui_info "$(get_static_message "python_dev_configuring_pyenv")"

  if [[ -z "$(pyenv versions --bare)" ]]; then
    ui_info "$(get_static_message "python_dev_installing_latest_python")"
    latest_python=$(pyenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    if [[ -n "$latest_python" ]]; then
      pyenv install "$latest_python" 2>/dev/null || true
      pyenv global "$latest_python" 2>/dev/null || true
    fi
  fi
fi

ui_info "$(get_static_message "python_dev_creating_directories")"
mkdir -p "$HOME/.local/bin" 2>/dev/null || true
mkdir -p "$HOME/.cache/pip" 2>/dev/null || true

ui_action_success "$(get_static_message "python_dev_configuration_completed")"
