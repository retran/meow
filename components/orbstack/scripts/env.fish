# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/orbstack/scripts/env.fish
# @brief: Fish-native env for OrbStack — activates OrbStack shell integration.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_ORBSTACK_ENV_FISH_SOURCED
    return 0
end
set -g _COMPONENT_ORBSTACK_ENV_FISH_SOURCED 1

# OrbStack fish integration
if test -f "$HOME/.orbstack/shell/init2.fish"
    source "$HOME/.orbstack/shell/init2.fish" 2>/dev/null; or true
end
