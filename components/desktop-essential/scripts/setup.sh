#!/usr/bin/env bash
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
# @file: components/desktop-essential/scripts/setup.sh
# @brief: Setup script for desktop applications and system utilities installation.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

if [ "${OSTYPE#darwin}" = "${OSTYPE}" ]; then
  ui_warning "This component is designed exclusively for macOS."
  exit 0
fi

# Global array to collect summary messages from sub-functions.
summary_msgs=""

is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

configure_macos_defaults() {
  ui_step_header "System Defaults"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping macOS default settings configuration."
    return 0
  fi

  ui_action_start "Applying general macOS system preferences..."

  osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1 || true

  if ui_confirm "Do you want to set a new computer name?"; then
    ui_info "Enter your desired computer name:"
    read -r computer_name
    if [ -n "$computer_name" ]; then
      sudo scutil --set ComputerName "$computer_name" >/dev/null 2>&1
      sudo scutil --set HostName "$computer_name" >/dev/null 2>&1
      sudo scutil --set LocalHostName "$computer_name" >/dev/null 2>&1
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name" >/dev/null 2>&1
      ui_action_success "Computer name set to $computer_name"
    else
      ui_info "Computer name not set. Skipping."
    fi
  fi

  ui_info "Configuring Homebrew PATH for privileged commands..."
  sudo launchctl config user path "$(brew --prefix)/bin:${PATH}" >/dev/null 2>&1
  ui_action_success "Homebrew PATH configured."

  ui_info "Applying general UI/UX settings..."
  sudo nvram SystemAudioVolume=" " >/dev/null 2>&1
  defaults write com.apple.finder AppleShowAllFiles -boolean true >/dev/null 2>&1
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false >/dev/null 2>&1
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001 >/dev/null 2>&1
  ui_action_success "General UI/UX settings applied."

  ui_info "Applying keyboard settings..."
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false >/dev/null 2>&1
  defaults write NSGlobalDomain KeyRepeat -int 1 >/dev/null 2>&1
  defaults write NSGlobalDomain InitialKeyRepeat -int 15 >/dev/null 2>&1
  ui_action_success "Keyboard settings applied."

  ui_action_start "Applying input device settings..."
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true >/dev/null 2>&1
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1 >/dev/null 2>&1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1 >/dev/null 2>&1
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40 >/dev/null 2>&1
  ui_action_success "Input device settings applied."

  ui_info "Applying energy saving settings..."
  sudo pmset -c displaysleep 15 >/dev/null 2>&1
  sudo pmset -b displaysleep 5 >/dev/null 2>&1
  sudo pmset -b sleep 15 >/dev/null 2>&1
  sudo pmset -c sleep 30 >/dev/null 2>&1
  sudo pmset -a hibernatemode 0 >/dev/null 2>&1
  ui_action_success "Energy saving settings applied."

  ui_action_success "macOS system defaults configured."
  summary_msgs="$summary_msgs
✓ macOS defaults: configured"
  return 0
}

configure_macos_finder() {
  ui_step_header "Finder Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping Finder configuration."
    return 0
  fi

  ui_action_start "Applying Finder preferences..."

  osascript -e 'tell application "Finder" to quit' >/dev/null 2>&1 || true

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true >/dev/null 2>&1
  defaults write com.apple.finder ShowPathbar -bool true >/dev/null 2>&1
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" >/dev/null 2>&1
  defaults write com.apple.finder _FXSortFoldersFirst -bool true >/dev/null 2>&1
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" >/dev/null 2>&1
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false >/dev/null 2>&1
  defaults write com.apple.finder QuitMenuItem -bool false >/dev/null 2>&1

  defaults write NSGlobalDomain com.apple.springing.enabled -bool true >/dev/null 2>&1
  defaults write NSGlobalDomain com.apple.springing.delay -float 0 >/dev/null 2>&1
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true >/dev/null 2>&1
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true >/dev/null 2>&1

  /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist" >/dev/null 2>&1
  /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist" >/dev/null 2>&1
  /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist" >/dev/null 2>&1

  chflags nohidden "${HOME}/Library" >/dev/null 2>&1
  sudo chflags nohidden /Volumes >/dev/null 2>&1

  open -a Finder >/dev/null 2>&1

  ui_action_success "Finder configured."
  summary_msgs="$summary_msgs
✓ Finder: configured"
  return 0
}

configure_macos_dock() {
  ui_step_header "Dock Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping Dock configuration."
    return 0
  fi

  ui_action_start "Applying Dock preferences..."
  defaults write com.apple.dock tilesize -int 48 >/dev/null 2>&1
  defaults write com.apple.dock minimize-to-application -bool true >/dev/null 2>&1
  defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true >/dev/null 2>&1
  defaults write com.apple.dock show-process-indicators -bool true >/dev/null 2>&1
  defaults write com.apple.dock expose-animation-duration -float 0.1 >/dev/null 2>&1
  defaults write com.apple.dock expose-group-by-app -bool false >/dev/null 2>&1
  defaults write com.apple.dock mru-spaces -bool false >/dev/null 2>&1
  defaults write com.apple.dock autohide-delay -float 0 >/dev/null 2>&1
  defaults write com.apple.dock autohide -bool true >/dev/null 2>&1
  defaults write com.apple.dock showhidden -bool true >/dev/null 2>&1
  defaults write com.apple.dock show-recents -bool false >/dev/null 2>&1
  killall Dock >/dev/null 2>&1 || true
  ui_action_success "Dock configured."
  summary_msgs="$summary_msgs
✓ Dock: configured"
  return 0
}

configure_macos_apps() {
  ui_step_header "App Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping application configuration."
    return 0
  fi

  ui_action_start "Applying macOS application preferences..."

  ui_action_start "Applying Photos application preferences..."
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true >/dev/null 2>&1
  ui_action_success "Photos application preferences applied."

  ui_action_start "Applying TextEdit application preferences..."
  defaults write com.apple.TextEdit RichText -int 0 >/dev/null 2>&1
  defaults write com.apple.TextEdit PlainTextEncoding -int 4 >/dev/null 2>&1
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4 >/dev/null 2>&1
  ui_action_success "TextEdit application preferences applied."

  ui_action_start "Applying Disk Utility preferences..."
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true >/dev/null 2>&1
  defaults write com.apple.DiskUtility advanced-image-options -bool true >/dev/null 2>&1
  ui_action_success "Disk Utility preferences applied."

  ui_action_start "Applying Time Machine preferences..."
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true >/dev/null 2>&1
  ui_action_success "Time Machine preferences applied."

  ui_action_start "Applying Spotlight settings..."
  # If ~/workspace does not exist, 'touch' will create the file directly in HOME.
  touch "${HOME}/workspace/.metadata_never_index" >/dev/null 2>&1
  sudo mdutil -E / >/dev/null 2>&1
  ui_action_success "Spotlight settings applied."

  ui_action_start "Applying Console application settings..."
  defaults write com.apple.Console DebugMenu -bool true >/dev/null 2>&1
  defaults write com.apple.Console ShowDeveloperLogs -bool true >/dev/null 2>&1
  ui_action_success "Console application settings applied."

  ui_action_start "Applying screen capture settings..."
  mkdir -p "${HOME}/Pictures/Screenshots" >/dev/null 2>&1
  defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots" >/dev/null 2>&1
  defaults write com.apple.screencapture type -string "png" >/dev/null 2>&1
  ui_action_success "Screen capture settings applied."

  ui_action_start "Applying Mail application settings..."
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false >/dev/null 2>&1
  defaults write com.apple.mail DisableInlineAttachmentViewing -bool true >/dev/null 2>&1
  ui_action_success "Mail application settings applied."

  ui_action_success "macOS application configuration completed."
  summary_msgs="$summary_msgs
✓ Apps: configured"
  return 0
}

# Execute the configuration functions
ui_step_header "Desktop Essential (${COMPONENT_NAME}) macOS Configuration"

if configure_macos_defaults; then
  :
else
  summary_msgs="$summary_msgs
✗ macOS defaults: failed"
fi

if configure_macos_finder; then
  :
else
  summary_msgs="$summary_msgs
✗ Finder: failed"
fi

if configure_macos_dock; then
  :
else
  summary_msgs="$summary_msgs
✗ Dock: failed"
fi

if configure_macos_apps; then
  :
else
  summary_msgs="$summary_msgs
✗ Apps: failed"
fi

if [ -n "$summary_msgs" ]; then
  ui_info "--- Configuration Summary ---"
  echo "$summary_msgs" | while read -r msg; do
    if [ -n "$msg" ]; then
      ui_info "$msg"
    fi
  done
fi

ui_action_success "Desktop Essential (${COMPONENT_NAME}) macOS configuration completed."
