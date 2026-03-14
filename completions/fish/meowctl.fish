# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: completions/fish/meowctl.fish
# @brief: Fish completion for meowctl
# @author: Andrew Vasilyev
# @license: MIT

# ============================================================================
# Helper functions
# ============================================================================

function __meowctl_list_presets
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    if test -d "$meow/presets"
        command ls -1 "$meow/presets"
    end
end

function __meowctl_list_components
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    if test -d "$meow/components"
        command ls -1 "$meow/components"
    end
end

function __meowctl_list_installed_components
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    if test -d "$meow/.installed/components"
        command ls -1 "$meow/.installed/components"
    end
end

function __meowctl_list_theme_presets
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    set -l db "$meow/themes.yaml"
    if test -f "$db"
        if command -q yq
            yq eval '.themes | keys | .[]' "$db" 2>/dev/null
        end
    end
end

function __meowctl_list_theme_variants
    set -l preset $argv[1]
    set -l meow (set -q MEOW; and echo $MEOW; or echo "$HOME/.meow")
    set -l db "$meow/themes.yaml"
    if test -f "$db"; and command -q yq
        yq eval ".themes.$preset.variants | keys | .[]" "$db" 2>/dev/null
    end
end

# ============================================================================
# Top-level subcommands
# ============================================================================

set -l cmds install update uninstall list component config theme backup help

complete -c meowctl -f

# Global flags
complete -c meowctl -s v -l verbose    -d 'Show detailed output'
complete -c meowctl -l dry-run         -d 'Show what would be done without changes'
complete -c meowctl -s h -l help       -d 'Show help'

# Top-level commands (only when no subcommand yet)
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a install   -d 'Install a preset'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a update    -d 'Update preset or all installed components'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a uninstall -d 'Uninstall a preset'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a list      -d 'List available presets'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a component -d 'Manage components'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a config    -d 'Manage meow configuration'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a theme     -d 'Manage themes'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a backup    -d 'Manage symlink backups'
complete -c meowctl -n "not __fish_seen_subcommand_from $cmds" -a help      -d 'Show help for command'

# ============================================================================
# install
# ============================================================================
complete -c meowctl -n "__fish_seen_subcommand_from install" -l force   -d 'Force reinstall'
complete -c meowctl -n "__fish_seen_subcommand_from install; and not __fish_seen_subcommand_from (__meowctl_list_presets)" \
    -a "(__meowctl_list_presets)"

# ============================================================================
# uninstall
# ============================================================================
complete -c meowctl -n "__fish_seen_subcommand_from uninstall; and not __fish_seen_subcommand_from (__meowctl_list_presets) all" \
    -a "(__meowctl_list_presets)"
complete -c meowctl -n "__fish_seen_subcommand_from uninstall" -a all -d 'Uninstall all presets'

# ============================================================================
# update
# ============================================================================
complete -c meowctl -n "__fish_seen_subcommand_from update" -l pull -d 'Pull latest changes from git'
complete -c meowctl -n "__fish_seen_subcommand_from update" \
    -a "(__meowctl_list_presets)"

# ============================================================================
# component subcommands
# ============================================================================
set -l component_cmds list status install uninstall update

complete -c meowctl -n "__fish_seen_subcommand_from component; and not __fish_seen_subcommand_from $component_cmds" \
    -a list      -d 'List all available components'
complete -c meowctl -n "__fish_seen_subcommand_from component; and not __fish_seen_subcommand_from $component_cmds" \
    -a status    -d 'Show status of all components'
complete -c meowctl -n "__fish_seen_subcommand_from component; and not __fish_seen_subcommand_from $component_cmds" \
    -a install   -d 'Install a component'
complete -c meowctl -n "__fish_seen_subcommand_from component; and not __fish_seen_subcommand_from $component_cmds" \
    -a uninstall -d 'Uninstall a component'
complete -c meowctl -n "__fish_seen_subcommand_from component; and not __fish_seen_subcommand_from $component_cmds" \
    -a update    -d 'Update a component'

complete -c meowctl -n "__fish_seen_subcommand_from component; and __fish_seen_subcommand_from install update" \
    -a "(__meowctl_list_components)"
complete -c meowctl -n "__fish_seen_subcommand_from component; and __fish_seen_subcommand_from uninstall" \
    -a "(__meowctl_list_installed_components)"

# ============================================================================
# theme subcommands
# ============================================================================
set -l theme_cmds apply toggle preset auto manual status preview list build

complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a apply   -d 'Apply the current theme'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a toggle  -d 'Toggle between light and dark mode'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a preset  -d 'Apply a specific theme preset'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a auto    -d 'Enable auto mode (follow system appearance)'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a manual  -d 'Enable manual mode'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a status  -d 'Show current theme status'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a preview -d 'Preview a theme without applying it'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a list    -d 'List all available themes'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and not __fish_seen_subcommand_from $theme_cmds" \
    -a build   -d 'Build theme files from themes.yaml'

# theme preset / preview — arg 1: preset name, arg 2: variant, arg 3 (preset only): mode
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from preset preview; and __fish_nth_token 3" \
    -a "(__meowctl_list_theme_presets)"
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from preset preview; and __fish_nth_token 4" \
    -a "(set p (__fish_commandline_first_non_option 3); __meowctl_list_theme_variants \$p)"
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from preset; and __fish_nth_token 5" \
    -a "light dark"

# theme build flags
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from build" \
    -l preset   -d 'Specific preset to build' -a "(__meowctl_list_theme_presets)"
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from build" \
    -l variant  -d 'Specific variant to build'
complete -c meowctl -n "__fish_seen_subcommand_from theme; and __fish_seen_subcommand_from build" \
    -l parallel -d 'Build in parallel'

# ============================================================================
# config subcommands
# ============================================================================
set -l config_cmds get set list

complete -c meowctl -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from $config_cmds" \
    -a get  -d 'Get a configuration value'
complete -c meowctl -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from $config_cmds" \
    -a set  -d 'Set a configuration value'
complete -c meowctl -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from $config_cmds" \
    -a list -d 'List all configuration values'

set -l config_keys \
    theme.mode \
    theme.current \
    theme.light.preset \
    theme.light.variant \
    theme.dark.preset \
    theme.dark.variant

complete -c meowctl -n "__fish_seen_subcommand_from config; and __fish_seen_subcommand_from get set" \
    -a "$config_keys"

# ============================================================================
# backup subcommands
# ============================================================================
complete -c meowctl -n "__fish_seen_subcommand_from backup; and not __fish_seen_subcommand_from list restore" \
    -a list    -d 'List all backup entries'
complete -c meowctl -n "__fish_seen_subcommand_from backup; and not __fish_seen_subcommand_from list restore" \
    -a restore -d 'Restore a backup'

# ============================================================================
# help
# ============================================================================
complete -c meowctl -n "__fish_seen_subcommand_from help" \
    -a "install update uninstall list component config theme backup"
