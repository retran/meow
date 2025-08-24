#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "python_dev_cleanup_running")"

if command -v pip >/dev/null 2>&1; then
  ui_info "$(fmt "python_dev_cleaning_pip_cache")"
  pip cache purge 2>/dev/null || true
fi

if command -v pip3 >/dev/null 2>&1; then
  ui_info "$(fmt "python_dev_cleaning_pip3_cache")"
  pip3 cache purge 2>/dev/null || true
fi

ui_info "$(fmt "python_dev_cleaning_bytecode")"
find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

if [[ -d "$HOME/.pytest_cache" ]]; then
  ui_info "$(fmt "python_dev_removing_pytest_cache")"
  rm -rf "$HOME/.pytest_cache" || true
fi

if [[ -d "$HOME/.mypy_cache" ]]; then
  ui_info "$(fmt "python_dev_removing_mypy_cache")"
  rm -rf "$HOME/.mypy_cache" || true
fi

if [[ -d "$HOME/.ipython" ]]; then
  ui_info "$(fmt "python_dev_cleaning_ipython_cache")"
  find "$HOME/.ipython" -name "*.pyc" -delete 2>/dev/null || true
  find "$HOME/.ipython" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
fi

ui_success "$(fmt "python_dev_cleanup_completed")"
