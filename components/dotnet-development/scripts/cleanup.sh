#!/usr/bin/env bash

# .NET Development component cleanup script
# This script is executed when the dotnet-development component is being uninstalled

set -euo pipefail

echo "🧹 Running .NET Development cleanup..."

# Clear NuGet cache
if command -v dotnet >/dev/null 2>&1; then
  echo "  📦 Cleaning NuGet cache..."
  dotnet nuget locals all --clear 2>/dev/null || true

  echo "  🗑️  Cleaning .NET temporary files..."
  dotnet clean 2>/dev/null || true
fi

# Clean up NuGet packages cache manually if needed
if [[ -d "$HOME/.nuget/packages" ]]; then
  echo "  🗑️  Cleaning NuGet packages cache..."
  rm -rf "$HOME/.nuget/packages/.tools" 2>/dev/null || true
fi

# Clean up Visual Studio Code omnisharp cache
if [[ -d "$HOME/.omnisharp" ]]; then
  echo "  🗑️  Cleaning OmniSharp cache..."
  rm -rf "$HOME/.omnisharp" 2>/dev/null || true
fi

# Clean up dotnet temp directories
if [[ -d "/tmp/.dotnet" ]]; then
  echo "  🗑️  Cleaning dotnet temp files..."
  rm -rf "/tmp/.dotnet" 2>/dev/null || true
fi

echo "✅ .NET Development cleanup completed"
