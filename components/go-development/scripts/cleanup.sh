#!/usr/bin/env bash

# Go Development component cleanup script
# This script is executed when the go-development component is being uninstalled

set -euo pipefail

echo "🧹 Running Go Development cleanup..."

# Clear Go module cache
if command -v go >/dev/null 2>&1; then
    echo "  📦 Cleaning Go module cache..."
    go clean -modcache 2>/dev/null || true

    echo "  🗑️  Cleaning Go build cache..."
    go clean -cache 2>/dev/null || true

    echo "  🗑️  Cleaning Go test cache..."
    go clean -testcache 2>/dev/null || true
fi

# Remove Go workspace configuration if exists
if [[ -f "$HOME/go.work" ]]; then
    echo "  🗑️  Removing Go workspace file..."
    rm -f "$HOME/go.work" || true
fi

# Clean up any leftover build artifacts in GOPATH
if [[ -n "${GOPATH:-}" && -d "$GOPATH/pkg" ]]; then
    echo "  🗑️  Cleaning GOPATH pkg directory..."
    rm -rf "$GOPATH/pkg" 2>/dev/null || true
fi

echo "✅ Go Development cleanup completed"
