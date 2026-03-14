# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/shell-essential/config/fish/conf.d/terminal-title.fish
# @brief: Dynamic terminal title showing user@host: cwd (or running command).
# @author: Andrew Vasilyev
# @license: MIT

function fish_title --description 'Set the terminal title'
    # While a command is running, show: cmd — user@host: cwd
    # Otherwise show: user@host: cwd
    set -l cmd (status current-command)
    set -l cwd (prompt_pwd --full-length-dirs 1)

    if test "$cmd" = fish
        echo "$USER@$hostname: $cwd"
    else
        echo "$cmd — $USER@$hostname: $cwd"
    end
end
