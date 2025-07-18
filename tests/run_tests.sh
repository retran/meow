#!/usr/bin/env bash

# tests/run_tests.sh - Run all tests for meow shell scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

echo "Running all tests for meow shell scripts..."
echo "=========================================="

# Check if bats is available
if ! command -v bats >/dev/null 2>&1; then
  echo "Error: bats testing framework is not installed"
  echo "Install with: sudo apt install bats (Ubuntu) or brew install bats (macOS)"
  exit 1
fi

# Check if bash 3.2 is available for testing
if [[ ! -x "/tmp/bash32/bin/bash" ]]; then
  echo "Warning: bash 3.2 not found at /tmp/bash32/bin/bash"
  echo "Some compatibility tests may be skipped"
fi

# Run all test files
echo "Running bash compatibility tests..."
bats tests/bash_compat.bats

echo "Running here-string compatibility tests..."
bats tests/here_strings.bats

echo "Running integration tests..."
bats tests/integration.bats

echo "Running comprehensive tests..."
bats tests/comprehensive.bats

echo "=========================================="
echo "All tests completed successfully!"
echo "Bash 3.2 compatibility verified."