# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/shell-essential/config/fish/conf.d/meow-components.fish
# @brief: Source each installed component's init.fish (preferred) or init.sh (fallback via bass).
# @author: Andrew Vasilyev
# @license: MIT

set -l meow_root "$HOME/.meow"
if set -q MEOW
    set meow_root "$MEOW"
end

for _component_dir in "$meow_root"/.installed/components/*
    set -l _component_name (basename "$_component_dir")

    # Prefer native fish init script; fall back to bash via bass
    set -l _fish_init "$meow_root/components/$_component_name/scripts/init.fish"
    set -l _bash_init "$meow_root/components/$_component_name/scripts/init.sh"

    if test -f "$_fish_init"
        source "$_fish_init" 2>/dev/null; or true
    else if test -f "$_bash_init"
        # bass not yet installed — skip silently (happens during fisher bootstrap)
        if functions -q bass
            bass source "$_bash_init" 2>/dev/null; or true
        end
    end
end

