#!/usr/bin/env bash

# Source the UI library for consistent messaging.
# MEOW is expected to be an environment variable defining the base path.
source "${MEOW}/lib/core/ui.sh"

ui_info "Starting adaptive keyboard layout cleanup..."

# Check if the operating system is macOS (Darwin).
# Using 'case' for robust Bash 3.2 compatibility and POSIX compliance.
case "$OSTYPE" in
  darwin*)
    ui_info "Cleaning macOS keyboard preferences..."

    # Remove a backup of the HIToolbox preferences file.
    # Errors are suppressed as the file may not exist.
    rm -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist.backup" 2>/dev/null || true

    # Remove the system-wide HIToolbox preferences file. Requires superuser privileges.
    # Errors are suppressed as the file may not exist.
    sudo rm -f /Library/Preferences/com.apple.HIToolbox.plist 2>/dev/null || true

    # Delete specific input source settings from the HIToolbox preferences.
    # Errors are suppressed if the keys do not exist.
    defaults delete com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null || true
    defaults delete com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null || true
    ;;
esac

ui_info "Cleaning temporary keyboard layout files..."
# Remove any temporary keyboard layout files.
# Errors are suppressed if no matching files are found.
rm -rf "/tmp/keyboard_layout_*" 2>/dev/null || true

ui_success "Adaptive keyboard layout cleanup completed successfully."
