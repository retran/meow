# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/shell-essential/config/fish/conf.d/meow-components.fish
# @brief: Source each installed component's init.fish.
# @author: Andrew Vasilyev
# @license: MIT

set -l meow_root "$HOME/.meow"
if set -q MEOW
    set meow_root "$MEOW"
end

for _component_dir in "$meow_root"/.installed/components/*
    set -l _component_name (basename "$_component_dir")

    # Source native fish init script if present
    set -l _fish_init "$meow_root/components/$_component_name/scripts/init.fish"

    if test -f "$_fish_init"
        source "$_fish_init" 2>/dev/null; or true
    end
end

