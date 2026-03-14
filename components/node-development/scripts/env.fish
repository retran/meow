# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/node-development/scripts/env.fish
# @brief: Fish-native env for Node.js development — sets NPM_CONFIG_PREFIX, PATH, and cache dir.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_NODE_DEVELOPMENT_ENV_FISH_SOURCED
    return 0
end
set -g _COMPONENT_NODE_DEVELOPMENT_ENV_FISH_SOURCED 1

set -gx NPM_CONFIG_PREFIX "$HOME/.npm-global"
if test -d "$NPM_CONFIG_PREFIX/bin"
    fish_add_path "$NPM_CONFIG_PREFIX/bin"
end

set -gx TS_NODE_CACHE_DIRECTORY "$HOME/.cache/ts-node"
