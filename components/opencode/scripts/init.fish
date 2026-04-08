# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/opencode/scripts/init.fish
# @brief: Fish-native init for OpenCode — enables built-in Exa search and LSP tool.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_OPENCODE_INIT_FISH_SOURCED
    return 0
end
set -g _COMPONENT_OPENCODE_INIT_FISH_SOURCED 1

# Enable built-in Exa web search (no API key required)
set -gx OPENCODE_ENABLE_EXA 1

# Enable experimental LSP tool (requires the lsp permission in opencode.json)
set -gx OPENCODE_EXPERIMENTAL_LSP_TOOL true
