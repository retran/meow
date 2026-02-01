#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: components/theme-manager/config/themes/theme-db.sh
# @brief: Theme database matching Neovim presets
# @author: Andrew Vasilyev
# @license: MIT

# Theme database - matches Neovim day_night_presets.lua
# Each theme defines:
# - name: Display name
# - description: Theme description
# - mood: Aesthetic vibe
# - day_theme, day_variant: Light variant
# - night_theme, night_variant: Dark variant
# - ghostty_*: Terminal colors
# - starship_palette: Starship color scheme
# - tmux_plugin: tmux theme plugin/colors

declare -A THEMES

# Everforest - Soft & Natural
THEMES[everforest]='
name="Everforest"
description="Organic colors, warm tones, minimal eye strain"
mood="Soft & Natural"
day_theme="everforest"
day_variant="light_soft"
night_theme="everforest"
night_variant="dark_medium"
starship_palette="gruvbox_light|gruvbox_dark"
tmux_theme="everforest"
'

# Catppuccin - Sweet & Modern
THEMES[catppuccin]='
name="Catppuccin"
description="Pastel colors, modern aesthetic, huge ecosystem"
mood="Sweet & Modern"
day_theme="catppuccin"
day_variant="latte"
night_theme="catppuccin"
night_variant="mocha"
starship_palette="default"
tmux_theme="catppuccin"
tmux_flavor="latte|mocha"
'

# Tokyo Night - Tech & Future
THEMES[tokyonight]='
name="Tokyo Night"
description="Clean, professional, excellent LSP support"
mood="Tech & Future"
day_theme="tokyonight"
day_variant="day"
night_theme="tokyonight"
night_variant="storm"
starship_palette="default"
tmux_theme="tokyonight"
'

# Kanagawa - Classic & Artistic
THEMES[kanagawa]='
name="Kanagawa"
description="Japanese art-inspired, deep colors, elegant"
mood="Classic & Artistic"
day_theme="kanagawa"
day_variant="lotus"
night_theme="kanagawa"
night_variant="wave"
starship_palette="default"
tmux_theme="kanagawa"
'

# Rose Pine - Calm & Minimal
THEMES[rosepine]='
name="Rose Pine"
description="Minimal palette, mountain sunset vibes"
mood="Calm & Minimal"
day_theme="rose-pine"
day_variant="dawn"
night_theme="rose-pine"
night_variant="main"
starship_palette="default"
tmux_theme="rose-pine"
'

# Nightfox - Sharp & Technical
THEMES[nightfox]='
name="Nightfox"
description="High contrast, excellent readability"
mood="Sharp & Technical"
day_theme="nightfox"
day_variant="dayfox"
night_theme="nightfox"
night_variant="nightfox"
starship_palette="default"
tmux_theme="nightfox"
'

# Solarized - Professional Lab
THEMES[solarized]='
name="Solarized Osaka"
description="Mathematically precise contrast"
mood="Professional Lab"
day_theme="solarized-osaka"
day_variant="day"
night_theme="solarized-osaka"
night_variant="night"
starship_palette="default"
tmux_theme="solarized"
'

# Zenbones - Pure Focus
THEMES[zenbones]='
name="Zenbones"
description="No visual noise, maximum focus"
mood="Pure Focus"
day_theme="zenbones"
day_variant="zenwritten"
night_theme="zenbones"
night_variant="zenbones"
starship_palette="default"
tmux_theme="zenbones"
'

# Ayu - Design Studio
THEMES[ayu]='
name="Ayu"
description="From Sublime Text, very clean"
mood="Design Studio"
day_theme="ayu"
day_variant="light"
night_theme="ayu"
night_variant="dark"
starship_palette="default"
tmux_theme="ayu"
'

# Gruvbox - Retro & Cozy
THEMES[gruvbox]='
name="Gruvbox"
description="Warm retro colors, cozy feel"
mood="Retro & Cozy"
day_theme="gruvbox"
day_variant="soft"
night_theme="gruvbox"
night_variant="medium"
starship_palette="gruvbox_light|gruvbox_dark"
tmux_theme="gruvbox"
'

# Dracula - Dark Legend
THEMES[dracula]='
name="Dracula"
description="The legendary dark theme"
mood="Dark Legend"
day_theme="ayu"
day_variant="light"
night_theme="dracula"
night_variant=""
starship_palette="default"
tmux_theme="dracula"
'

# Monokai Pro - Pro Studio
THEMES[monokai]='
name="Monokai Pro"
description="Professional favorite, high contrast"
mood="Pro Studio"
day_theme="monokai-pro"
day_variant="classic"
night_theme="monokai-pro"
night_variant="pro"
starship_palette="default"
tmux_theme="monokai"
'

# One Dark - Developer Standard
THEMES[onedark]='
name="One Dark"
description="From Atom/VS Code, balanced"
mood="Developer Standard"
day_theme="onedark"
day_variant="onelight"
night_theme="onedark"
night_variant="onedark"
starship_palette="default"
tmux_theme="onedark"
'

# Material - Material & Modern
THEMES[material]='
name="Material"
description="Google Material Design"
mood="Material & Modern"
day_theme="material"
day_variant="lighter"
night_theme="material"
night_variant="darker"
starship_palette="default"
tmux_theme="material"
'

# Melange - Warm Harmony
THEMES[melange]='
name="Melange"
description="Warm balanced colors (dark only)"
mood="Warm Harmony"
day_theme="everforest"
day_variant="light_soft"
night_theme="melange"
night_variant=""
starship_palette="gruvbox_light|gruvbox_dark"
tmux_theme="melange"
'

# GitHub - GitHub Official
THEMES[github]='
name="GitHub"
description="Official GitHub theme"
mood="GitHub Official"
day_theme="github"
day_variant="github_light"
night_theme="github"
night_variant="github_dark"
starship_palette="default"
tmux_theme="github"
'

# Helper functions
get_preset_list() {
    for preset in "${!THEMES[@]}"; do
        echo "$preset"
    done | sort
}

get_preset_info() {
    local preset="$1"
    local field="$2"
    
    if [[ -z "${THEMES[$preset]}" ]]; then
        return 1
    fi
    
    eval "${THEMES[$preset]}"
    eval "echo \$$field"
}

get_all_presets_formatted() {
    for preset in $(get_preset_list); do
        eval "${THEMES[$preset]}"
        printf "%s|%s|%s\n" "$preset" "$name" "$mood"
    done
}
