#!/usr/bin/env bash

# Python Development component cleanup script
# This script is executed when the python-development component is being uninstalled

set -euo pipefail

echo "🧹 Running Python Development cleanup..."

# Clear pip cache
if command -v pip >/dev/null 2>&1; then
  echo "  📦 Cleaning pip cache..."
  pip cache purge 2>/dev/null || true
fi

# Clear pip3 cache if available
if command -v pip3 >/dev/null 2>&1; then
  echo "  📦 Cleaning pip3 cache..."
  pip3 cache purge 2>/dev/null || true
fi

# Clean up Python bytecode files in common locations
echo "  🗑️  Cleaning Python bytecode files..."
find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up pytest cache
if [[ -d "$HOME/.pytest_cache" ]]; then
  echo "  🗑️  Removing pytest cache..."
  rm -rf "$HOME/.pytest_cache" || true
fi

# Clean up mypy cache
if [[ -d "$HOME/.mypy_cache" ]]; then
  echo "  🗑️  Removing mypy cache..."
  rm -rf "$HOME/.mypy_cache" || true
fi

# Clean up IPython/Jupyter cache
if [[ -d "$HOME/.ipython" ]]; then
  echo "  🗑️  Cleaning IPython cache..."
  find "$HOME/.ipython" -name "*.pyc" -delete 2>/dev/null || true
  find "$HOME/.ipython" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
fi

echo "✅ Python Development cleanup completed"
