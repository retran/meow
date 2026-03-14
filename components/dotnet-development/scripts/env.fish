# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/dotnet-development/scripts/env.fish
# @brief: Fish-native env for .NET development — sets PATH and disables telemetry.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_DOTNET_DEVELOPMENT_ENV_FISH_SOURCED
    return 0
end
set -g _COMPONENT_DOTNET_DEVELOPMENT_ENV_FISH_SOURCED 1

if test -d "$HOME/.dotnet/tools"
    fish_add_path "$HOME/.dotnet/tools"
end

set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
set -gx DOTNET_NOLOGO 1
