# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/shell-essential/config/fish/config.fish
# @brief: Fish shell main configuration for the meow dotfiles framework.
# @author: Andrew Vasilyev
# @license: MIT

# Suppress the default fish greeting
set -g fish_greeting

# ============================================================================
# MEOW / XDG environment
# ============================================================================
set -gx MEOW "$HOME/.meow"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx MEOW_CONFIG_DIR "$XDG_CONFIG_HOME/meow"
set -gx STARSHIP_CONFIG "$MEOW/components/shell-essential/config/starship/starship.toml"

# ============================================================================
# PATH
# ============================================================================

# Homebrew (macOS)
if test (uname -s) = Darwin
    if test -x /opt/homebrew/bin/brew
        fish_add_path /opt/homebrew/bin
        fish_add_path /opt/homebrew/sbin
    end

    # Prefer GNU coreutils/findutils over macOS BSD versions
    if test -d /opt/homebrew/opt/coreutils/libexec/gnubin
        fish_add_path /opt/homebrew/opt/coreutils/libexec/gnubin
    end
    if test -d /opt/homebrew/opt/findutils/libexec/gnubin
        fish_add_path /opt/homebrew/opt/findutils/libexec/gnubin
    end
end

# User-local binaries
fish_add_path "$HOME/.local/bin"

# fzf binary (if installed via git)
if test -d "$HOME/.fzf/bin"
    fish_add_path "$HOME/.fzf/bin"
end

# ============================================================================
# Source meow env — fish-native per-component env.fish first, then bash
# fallback via bass for components that only have env.sh
# ============================================================================

# Per-component env.fish (fish-native, preferred)
for _component_dir in "$MEOW"/.installed/components/*
    set -l _component_name (basename "$_component_dir")
    set -l _fish_env "$MEOW/components/$_component_name/scripts/env.fish"
    if test -f "$_fish_env"
        source "$_fish_env" 2>/dev/null; or true
    end
end

# lib/env/env.sh via bass — sets EDITOR, VISUAL, PATH additions for components
# without env.fish (pipx, cargo, npm-global, mise shims, etc.)
if functions -q bass
    if test -f "$MEOW/lib/env/env.sh"
        bass source "$MEOW/lib/env/env.sh"
    end
end

# ============================================================================
# Zellij auto-start (Ghostty / Alacritty terminals only)
# ============================================================================
if status is-interactive
    set -l _term "$TERM_PROGRAM"
    set -l _xterm "$TERM"
    if command -q zellij; and test -z "$ZELLIJ"
        if test "$_term" = Ghostty
            or test "$_term" = ghostty
            or test "$_xterm" = xterm-ghostty
            or test "$_xterm" = xterm-ghostty-256color
            or test "$_term" = Alacritty
            or test -n "$ALACRITTY_LOG"
            or test -n "$ALACRITTY_WINDOW_ID"

            exec zellij
        end
    end
end

# ============================================================================
# Tool integrations
# ============================================================================

# zoxide — replaces cd
if command -q zoxide
    zoxide init fish --cmd cd | source
end

# mise — activated via components/tool-installers/scripts/init.fish (sourced by meow-components.fish)

# starship prompt
if command -q starship
    starship init fish | source
end

# fzf key bindings (provided by PatrickF1/fzf.fish plugin)
# No explicit init needed — fzf.fish handles it via conf.d autoloading.

# ============================================================================
# Theme colours (FZF_DEFAULT_OPTS, EZA_COLORS, LS_COLORS)
# ============================================================================
_meow_source_theme_colors 2>/dev/null; or true
