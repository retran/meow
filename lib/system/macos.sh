#!/usr/bin/env bash

# lib/system/macos.sh - macOS system configuration functions

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_MACOS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_MACOS_SOURCED=1

source "${DOTFILES_DIR}/lib/core/ui.sh"

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

configure_macos_defaults() {
  local indent_level="${1:-1}"

  step_header "$indent_level" "System Defaults"

  if ! is_macos; then
    warning "$indent_level" "Not running on macOS. Skipping macOS configuration."
    return 1
  fi

  action_msg "$indent_level" "Configuring macOS preferences"

  osascript -e 'tell application "System Preferences" to quit'

  if ui_confirm "$indent_level" "Do you want to set a new computer name?"; then
    action_msg "$((indent_level + 1))" "Enter your desired computer name: "
    read -r computer_name
    if [[ -n "$computer_name" ]]; then
      sudo scutil --set ComputerName "$computer_name"
      sudo scutil --set HostName "$computer_name"
      sudo scutil --set LocalHostName "$computer_name"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"
      success_tick_msg "$((indent_level + 1))" "Computer name set to $computer_name"
    fi
  fi

  info "$indent_level" "Configuring brew PATH..."
  sudo launchctl config user path "$(brew --prefix)/bin:${PATH}"

  info "$indent_level" "Configuring general UI/UX settings..."

  sudo nvram SystemAudioVolume=" "

  defaults write com.apple.finder AppleShowAllFiles -boolean true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

  success_tick_msg "$((indent_level + 1))" "General UI/UX settings configured"

  action_msg "$((indent_level + 1))" "Configuring input device settings..."

  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

  success_tick_msg "$((indent_level + 1))" "Input device settings configured"

  info "$indent_level" "Configuring energy saving settings..."

  sudo pmset -c displaysleep 15
  sudo pmset -b displaysleep 5
  sudo pmset -b sleep 15
  sudo pmset -c sleep 30
  sudo pmset -a hibernatemode 0

  success_tick_msg "$((indent_level + 1))" "Energy saving settings configured"

  success_tick_msg "$indent_level" "System defaults configured"
  summary_msgs+=("✓ macOS defaults: configured")
  return 0
}

configure_macos_finder() {
  local indent_level="${1:-1}"

  step_header "$indent_level" "Finder Configuration"

  if ! is_macos; then
    warning "$indent_level" "Not running on macOS. Skipping Finder configuration."
    return 1
  fi

  action_msg "$indent_level" "Configuring Finder preferences"

  osascript -e 'tell application "Finder" to quit'

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  defaults write com.apple.finder ShowStatusBar -bool true

  defaults write com.apple.finder ShowPathbar -bool true

  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  defaults write NSGlobalDomain com.apple.springing.enabled -bool true
  defaults write NSGlobalDomain com.apple.springing.delay -float 0
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

  chflags nohidden ~/Library
  sudo chflags nohidden /Volumes

  open -a Finder

  success_tick_msg "$indent_level" "Finder configured"
  summary_msgs+=("✓ Finder: configured")
  return 0
}

configure_macos_dock() {
  local indent_level="${1:-1}"

  step_header "$indent_level" "Dock Configuration"

  if ! is_macos; then
    warning "$indent_level" "Not running on macOS. Skipping Dock configuration."
    return 1
  fi

  action_msg "$indent_level" "Configuring Dock preferences"

  defaults write com.apple.dock tilesize -int 48

  defaults write com.apple.dock minimize-to-application -bool true

  defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

  defaults write com.apple.dock show-process-indicators -bool true

  defaults write com.apple.dock expose-animation-duration -float 0.1

  defaults write com.apple.dock expose-group-by-app -bool false

  defaults write com.apple.dock mru-spaces -bool false

  defaults write com.apple.dock autohide-delay -float 0

  defaults write com.apple.dock autohide -bool true

  defaults write com.apple.dock showhidden -bool true

  defaults write com.apple.dock show-recents -bool false

  killall Dock

  success_tick_msg "$indent_level" "Dock configured"
  summary_msgs+=("✓ Dock: configured")
  return 0
}

configure_macos_apps() {
  local indent_level="${1:-1}"

  step_header "$indent_level" "App Configuration"

  if ! is_macos; then
    warning "$indent_level" "Not running on macOS. Skipping app configuration."
    return 1
  fi

  action_msg "$indent_level" "Configuring macOS application preferences"

  action_msg "$((indent_level + 1))" "Configuring Photos preferences..."
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
  success_tick_msg "$((indent_level + 1))" "Photos preferences configured"

  action_msg "$((indent_level + 1))" "Configuring TextEdit preferences..."
  defaults write com.apple.TextEdit RichText -int 0
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
  success_tick_msg "$((indent_level + 1))" "TextEdit preferences configured"

  action_msg "$((indent_level + 1))" "Configuring Disk Utility preferences..."
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true
  success_tick_msg "$((indent_level + 1))" "Disk Utility preferences configured"

  action_msg "$((indent_level + 1))" "Configuring Time Machine preferences..."
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
  success_tick_msg "$((indent_level + 1))" "Time Machine preferences configured"

  success_tick_msg "$indent_level" "App configuration completed"
  summary_msgs+=("✓ Apps: configured")
  return 0
}

configure_macos() {
  local indent_level="${1:-0}"
  local summary_msgs=()

  if ! is_macos; then
    info "$indent_level" "Not running on macOS. Skipping all macOS configuration."
    return 1
  fi

  step_header "$indent_level" "macOS Configuration"

  info "$indent_level" "This script will configure various macOS settings to enhance your experience."
  if ! ui_confirm "$indent_level" "Do you want to apply these macOS configurations?"; then
    warning "$indent_level" "macOS configuration cancelled."
    return 1
  fi

  if configure_macos_defaults "$((indent_level + 1))"; then
    :
  else
    summary_msgs+=("✗ macOS defaults: failed")
  fi

  if configure_macos_finder "$((indent_level + 1))"; then
    :
  else
    summary_msgs+=("✗ Finder: failed")
  fi

  if configure_macos_dock "$((indent_level + 1))"; then
    :
  else
    summary_msgs+=("✗ Dock: failed")
  fi

  if configure_macos_apps "$((indent_level + 1))"; then
    :
  else
    summary_msgs+=("✗ Apps: failed")
  fi

  if [ ${#summary_msgs[@]} -gt 0 ]; then
    info "$indent_level" "Summary:"
    for msg in "${summary_msgs[@]}"; do
      info "$((indent_level + 1))" "$msg"
    done
  fi

  success_tick_msg "$indent_level" "macOS configuration completed"
  info "$indent_level" "Some changes may require a logout or restart to take effect."
  return 0
}
