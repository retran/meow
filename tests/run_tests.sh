#!/usr/bin/env bash

# tests/run_tests.sh - Run functionality tests for meow shell scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

echo "Running functionality tests for meow shell scripts..."
echo "=================================================="

# Check if bats is available
if ! command -v bats >/dev/null 2>&1; then
  echo "Error: bats testing framework is not installed"
  echo "Install with: sudo apt install bats (Ubuntu) or brew install bats (macOS)"
  exit 1
fi

# Run integration tests
echo "Running integration tests..."
bats tests/integration.bats

echo "=================================================="
echo "All functionality tests completed successfully!"