# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: completions/fish/meow-theme.fish
# @brief: Fish completion for meow-theme
# @author: Andrew Vasilyev
# @license: MIT

# ============================================================================
# Helpers
# ============================================================================

function __meow_theme_list_presets
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    set -l db "$meow/themes.yaml"
    if test -f "$db"; and command -q yq
        yq eval '.themes | keys | .[]' "$db" 2>/dev/null
    end
end

function __meow_theme_list_variants
    set -l preset $argv[1]
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    set -l db "$meow/themes.yaml"
    if test -f "$db"; and command -q yq
        yq eval ".themes.$preset.variants | keys | .[]" "$db" 2>/dev/null
    end
end

# ============================================================================
# Completions
# ============================================================================

complete -c meow-theme -f

set -l cmds apply toggle preset auto manual status preview list

# Top-level commands
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a apply   -d 'Apply the current theme'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a toggle  -d 'Toggle between light and dark mode'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a preset  -d 'Apply a specific theme preset'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a auto    -d 'Enable auto mode (follow system appearance)'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a manual  -d 'Enable manual mode'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a status  -d 'Show current theme status'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a preview -d 'Preview a theme without applying it'
complete -c meow-theme -n "not __fish_seen_subcommand_from $cmds" -a list    -d 'List all available themes'

# preset / preview: arg positions 2=preset, 3=variant, 4=mode (preset only)
complete -c meow-theme -n "__fish_seen_subcommand_from preset preview; and __fish_nth_token 2" \
    -a "(__meow_theme_list_presets)"
complete -c meow-theme -n "__fish_seen_subcommand_from preset preview; and __fish_nth_token 3" \
    -a "(set p (commandline -opc)[2]; __meow_theme_list_variants \$p)"
complete -c meow-theme -n "__fish_seen_subcommand_from preset; and __fish_nth_token 4" \
    -a "light dark"
