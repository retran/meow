# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/go-task/scripts/init.fish
# @brief: Fish-native init for go-task — enables Task CLI completions.
# @author: Andrew Vasilyev
# @license: MIT

# Guard against double-sourcing
if set -q _COMPONENT_GO_TASK_INIT_FISH_SOURCED
    return 0
end
set -g _COMPONENT_GO_TASK_INIT_FISH_SOURCED 1

if not command -q task
    return 0
end

if status is-interactive
    task --completion fish | source
end
