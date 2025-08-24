#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "Starting adaptive keyboard layout cleanup..."

case "$OSTYPE" in
  darwin*)
    ui_info "Cleaning macOS keyboard preferences..."

    rm -f "$HOME/Library/Preferences/com.apple.HIToolbox.plist.backup" 2>/dev/null || true

    sudo rm -f /Library/Preferences/com.apple.HIToolbox.plist 2>/dev/null || true

    defaults delete com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null || true
    defaults delete com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null || true
    ;;
esac

ui_info "Cleaning temporary keyboard layout files..."
rm -rf "/tmp/keyboard_layout_*" 2>/dev/null || true

ui_success "Adaptive keyboard layout cleanup completed successfully."
