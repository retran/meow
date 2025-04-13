#!/usr/bin/env bash

# scripts/set_das_keyboard_layouts.sh - Script to set das keyboard layouts on macOS

is_russian_win_selected=$(defaults read com.apple.HIToolbox AppleSelectedInputSources | grep -c "Russian")

defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
    '<dict>
        <key>InputSourceKind</key>
        <string>Keyboard Layout</string>
        <key>KeyboardLayout ID</key>
        <integer>252</integer>
        <key>KeyboardLayout Name</key>
        <string>ABC</string>
    </dict>' \
    '<dict>
        <key>InputSourceKind</key>
        <string>Keyboard Layout</string>
        <key>KeyboardLayout ID</key>
        <integer>19458</integer>
        <key>KeyboardLayout Name</key>
        <string>RussianWin</string>
    </dict>'

if [[ "$is_russian_win_selected" -gt 0 ]]; then
    echo "Active Russian layout detected. Restoring it..."
    defaults write com.apple.HIToolbox AppleSelectedInputSources -array \
        '<dict>
            <key>InputSourceKind</key>
            <string>Keyboard Layout</string>
            <key>KeyboardLayout ID</key>
            <integer>19458</integer>
            <key>KeyboardLayout Name</key>
            <string>RussianWin</string>
        </dict>'
fi

pkill TextInputMenuAgent

echo "Done. Keyboard layouts have been configured."