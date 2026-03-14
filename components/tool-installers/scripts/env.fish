# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tool-installers/scripts/env.fish
# @brief: Fish-native env for tool installers — sets PATH for mise shims, pipx, cargo, npm-global.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_TOOL_INSTALLERS_ENV_FISH_SOURCED
    return 0
end
set -g _COMPONENT_TOOL_INSTALLERS_ENV_FISH_SOURCED 1

# mise binary and shims
fish_add_path "$HOME/.local/bin"

set -l _mise_shims "${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
if test -d "$_mise_shims"
    fish_add_path "$_mise_shims"
end

# pipx
set -gx PIPX_HOME "$HOME/.local/pipx"
set -gx PIPX_BIN_DIR "$HOME/.local/bin"

# cargo
if test -d "$HOME/.cargo/bin"
    fish_add_path "$HOME/.cargo/bin"
end

# npm global binaries
if test -d "$HOME/.npm-global/bin"
    fish_add_path "$HOME/.npm-global/bin"
end
