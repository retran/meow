# Changelog

All notable changes to the meow dotfiles framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

#### Terminal Stack Enhancements

- **Tmux Status Bar Monitoring**: Added comprehensive system monitoring to tmux status bar
  - CPU usage monitoring (`tmux-cpu` script)
  - Memory usage monitoring (`tmux-memory` script)
  - Battery status with charging indicators (`tmux-battery` script)
  - Weather information with 15-minute caching (`tmux-weather` script)
  - Status bar format: `CPU | Memory | Battery | Weather | Date | Time`

- **Tmux Productivity Features**:
  - Vim-aware pane navigation with `C-h/j/k/l` (seamless vim/tmux switching)
  - Three new plugins: `tmux-fingers`, `tmux-open`, `tmux-fzf`
  - Intuitive split keybindings: `prefix + |` (vertical), `prefix + -` (horizontal)
  - Pane swapping: `prefix + >` (next), `prefix + <` (previous)
  - Session navigation: `M-j/k` (Alt+j/k for next/previous session)
  - Window movement: `C-S-Left/Right` to move windows
  - Status bar toggle: `prefix + S`
  - Enhanced copy mode navigation: `C-u/d` for half-page scrolling
  - Clear screen and history: `prefix + C-l`
  - Even layout keybindings: `prefix + =` (horizontal), `prefix + +` (vertical)

- **Tmux Configuration Improvements**:
  - Increased history limit from 10,000 to 50,000 lines
  - Added RGB color and undercurl support for better terminal capabilities
  - Modernized clipboard integration (direct pbcopy/pbpaste, no reattach-to-user-namespace)
  - Process detection for vim-aware navigation
  - Cross-platform clipboard support (macOS/Linux)

- **Ghostty Terminal Configuration**:
  - Enabled shell integration (zsh with cursor, sudo, title features)
  - Added comprehensive performance settings (50k scrollback)
  - Configured clipboard protection and paste safety
  - Added window padding and state persistence
  - Added macOS-specific optimizations (titlebar style)
  - Configured keybindings for tabs, font size, and search
  - Documented quick terminal (Quake-style dropdown) feature

- **Starship Prompt Optimization**:
  - Reduced command timeout from 10s to 3s for better responsiveness
  - Disabled built-in modules that conflict with custom wrappers
  - Removed disabled modules from format string for cleaner output
  - Added comprehensive documentation for "cockpit features" (optional system monitoring)
  - Clarified division of responsibility between tmux status bar and prompt

#### Package Management Enhancements

- **Pipx Auto-Recovery**: Automatic detection and recovery of broken pipx virtual environments
  - Detects "No module named pip" errors (caused by Python version changes)
  - Automatically runs `pipx reinstall` instead of failing
  - Tracks reinstalled packages separately in update summary
  - Provides clear user feedback during recovery process
  - Handles Python upgrades (e.g., 3.13 → 3.14) gracefully

### Changed

#### Configuration Optimization

- **Tmux Configuration**: Streamlined from 278 to 215 lines (-23%)
  - Removed verbose inline comments
  - Consolidated related settings
  - Simplified section headers
  - Improved logical grouping

- **Ghostty Configuration**: Streamlined from 185 to 121 lines (-35%)
  - Removed redundant comments
  - Consolidated settings organization
  - Maintained all functionality

- **Starship Configuration**: Minor cleanup (-13 lines)
  - Simplified comment structure
  - Improved cockpit features documentation

- **Tmux Status Bar**: Redesigned with macOS-style aesthetics
  - Uniform text color (no colored backgrounds)
  - Monochrome nerd font icons
  - Cleaner, professional appearance

### Fixed

- **Ghostty Configuration**: Removed unsupported configuration fields
  - Removed `macos-auto-repeat`, `macos-auto-repeat-delay`, `macos-auto-repeat-rate`
  - Removed `max-fps`
  - Eliminated configuration validation errors

- **Pipx Package Updates**: Fixed update failures for packages with broken virtual environments
  - Previously: Failed with "No module named pip" error
  - Now: Automatically reinstalls packages when venv is broken
  - Affects: codespell, yamllint, poetry, pipenv, and other pipx packages

### Verified

- **Keybinding Compatibility**: Comprehensive analysis confirmed no conflicts
  - Tmux `C-h/j/k/l` navigation works seamlessly with nvim
  - nvim-cmp has proper fallback logic for completion navigation
  - Alt/Meta keys properly separated between tmux and nvim
  - All leader key mappings in separate namespaces

## File Changes Summary

### New Files
- `components/tmux/scripts/tmux-battery` - Battery status monitoring
- `components/tmux/scripts/tmux-cpu` - CPU usage monitoring  
- `components/tmux/scripts/tmux-memory` - Memory usage monitoring
- `components/tmux/scripts/tmux-weather` - Weather display with caching

### Modified Files
- `components/shell-essential/config/starship/starship.toml` - Optimization and cleanup
- `components/tmux/config/tmux/.tmux.conf` - Complete reorganization with new features
- `components/tmux/scripts/generate-theme-tmux` - Updated for new status bar format
- `components/terminal-apps/config/ghostty/config` - Comprehensive enhancement and cleanup
- `lib/package/pipx.sh` - Added auto-recovery for broken virtual environments

## Upgrade Notes

### Tmux Plugins

After pulling these changes, install new tmux plugins:

```bash
# In tmux, press: prefix + I (capital I)
```

This installs:
- `tmux-fingers` (prefix + F) - Fast link/path copying
- `tmux-open` (prefix + o) - Open files/URLs
- `tmux-fzf` (prefix + C-f) - Fuzzy finder integration

### Theme Reapplication

After pulling changes, reapply your theme to update all configs:

```bash
meowctl theme apply
```

### Ghostty Restart

Restart Ghostty to load the updated configuration with shell integration and enhanced features.

## Migration Guide

### Tmux Status Bar

The status bar now shows system monitoring by default. If you prefer the old behavior:

1. The monitoring scripts are independent and can be disabled by commenting out the status bar format in your theme
2. Starship "cockpit features" are disabled by default to avoid duplication

### Vim-Aware Navigation

The new `C-h/j/k/l` navigation is enabled by default and works out of the box with vim/nvim. For even better integration, consider installing the `christoomey/vim-tmux-navigator` plugin in neovim.

### Python Version Changes

The pipx auto-recovery feature handles Python version changes automatically. When Python updates:

1. `meowctl update` detects broken pipx packages
2. Automatically reinstalls them with the new Python version
3. No manual intervention required

## Breaking Changes

None. All changes are backward compatible.

## Known Issues

None.

## Credits

- Tmux vim-aware navigation inspired by `christoomey/vim-tmux-navigator`
- Status bar monitoring scripts designed for minimal overhead
- Ghostty configuration aligned with modern terminal emulator best practices
