#!/usr/bin/env bash

# Python Development component cleanup script
# This script is executed when the python-development component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "python_dev_cleanup_running")"

# Clear pip cache
if command -v pip >/dev/null 2>&1; then
  echo "$(get_static_message "python_dev_cleaning_pip_cache")"
  pip cache purge 2>/dev/null || true
fi

# Clear pip3 cache if available
if command -v pip3 >/dev/null 2>&1; then
  echo "$(get_static_message "python_dev_cleaning_pip3_cache")"
  pip3 cache purge 2>/dev/null || true
fi

# Clean up Python bytecode files in common locations
echo "$(get_static_message "python_dev_cleaning_bytecode")"
find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up pytest cache
if [[ -d "$HOME/.pytest_cache" ]]; then
  echo "$(get_static_message "python_dev_removing_pytest_cache")"
  rm -rf "$HOME/.pytest_cache" || true
fi

# Clean up mypy cache
if [[ -d "$HOME/.mypy_cache" ]]; then
  echo "$(get_static_message "python_dev_removing_mypy_cache")"
  rm -rf "$HOME/.mypy_cache" || true
fi

# Clean up IPython/Jupyter cache
if [[ -d "$HOME/.ipython" ]]; then
  echo "$(get_static_message "python_dev_cleaning_ipython_cache")"
  find "$HOME/.ipython" -name "*.pyc" -delete 2>/dev/null || true
  find "$HOME/.ipython" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
fi

echo "$(get_static_message "python_dev_cleanup_completed")"
