#!/usr/bin/env bash

# tests/run_tests.sh - Run functionality tests for meow shell scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

echo "Running functionality tests for meow shell scripts..."

if ! command -v bats >/dev/null 2>&1; then
  echo "Error: bats testing framework is not installed"
  echo "Install with: sudo apt install bats (Ubuntu) or brew install bats (macOS)"
  exit 1
fi

echo "Running integration tests..."
bats tests/integration.bats

echo "Running package manager tests..."
bats tests/package_manager.bats

echo "Running preset management tests..."
bats tests/preset_management.bats

echo "All functionality tests completed successfully!"
