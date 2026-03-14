# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/tool-installers/scripts/init.fish
# @brief: Fish-native init for tool installers — activates mise.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_TOOL_INSTALLERS_INIT_FISH_SOURCED
    return 0
end
set -g _COMPONENT_TOOL_INSTALLERS_INIT_FISH_SOURCED 1

# Activate mise (handles tool shims and PATH natively in fish)
if command -q mise
    mise activate fish | source
end
