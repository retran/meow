# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/shell-essential/config/fish/conf.d/meow-components.fish
# @brief: Source each installed component's init.sh via bass.
# @author: Andrew Vasilyev
# @license: MIT

# Requires edc/bass to be installed via Fisher.
# bass lets fish source bash/POSIX shell scripts and pick up exported variables.

if not functions -q bass
    # bass not yet installed — skip silently (happens during fisher bootstrap)
    exit 0
end

set -l meow_root "$HOME/.meow"
if set -q MEOW
    set meow_root "$MEOW"
end

for _init_script in "$meow_root"/.installed/components/*/scripts/init.sh
    if test -f "$_init_script"
        bass source "$_init_script" 2>/dev/null; or true
    end
end
