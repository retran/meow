#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_MACOS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_MACOS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

configure_macos_defaults() {
  step_header "System Defaults"

  if ! is_macos; then
    warning "Not running on macOS. Skipping macOS configuration."
    return 0
  fi

  action_msg "Configuring macOS preferences"

  osascript -e 'tell application "System Preferences" to quit'

  if ui_confirm "Do you want to set a new computer name?"; then
    action_msg "Enter your desired computer name: "
    read -r computer_name
    if [[ -n "$computer_name" ]]; then
      sudo scutil --set ComputerName "$computer_name"
      sudo scutil --set HostName "$computer_name"
      sudo scutil --set LocalHostName "$computer_name"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"
      success_tick_msg "Computer name set to $computer_name"
    fi
  fi

  info "Configuring brew PATH..."
  sudo launchctl config user path "$(brew --prefix)/bin:${PATH}"
  success_tick_msg "brew PATH configured"

  info "Configuring general UI/UX settings..."
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
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  success_tick_msg "General UI/UX settings configured"

  info "Configuring keyboard settings..."
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  success_tick_msg "Keyboard settings configured"

  action_msg "Configuring input device settings..."
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
  success_tick_msg "Input device settings configured"

  info "Configuring energy saving settings..."
  sudo pmset -c displaysleep 15
  sudo pmset -b displaysleep 5
  sudo pmset -b sleep 15
  sudo pmset -c sleep 30
  sudo pmset -a hibernatemode 0
  success_tick_msg "Energy saving settings configured"

  success_tick_msg "System defaults configured"
  summary_msgs+=("✓ macOS defaults: configured")
  return 0
}

configure_macos_finder() {
  step_header "Finder Configuration"

  if ! is_macos; then
    warning "Not running on macOS. Skipping Finder configuration."
    return 0
  fi

  action_msg "Configuring Finder preferences"

  osascript -e 'tell application "Finder" to quit'

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder QuitMenuItem -bool false

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

  success_tick_msg "Finder configured"
  summary_msgs+=("✓ Finder: configured")
  return 0
}

configure_macos_dock() {
  step_header "Dock Configuration"

  if ! is_macos; then
    warning "Not running on macOS. Skipping Dock configuration."
    return 0
  fi

  action_msg "Configuring Dock preferences"
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
  success_tick_msg "Dock configured"
  summary_msgs+=("✓ Dock: configured")
  return 0
}

configure_macos_apps() {
  step_header "App Configuration"

  if ! is_macos; then
    warning "Not running on macOS. Skipping app configuration."
    return 0
  fi

  action_msg "Configuring macOS application preferences"

  action_msg "Configuring Photos preferences..."
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
  success_tick_msg "Photos preferences configured"

  action_msg "Configuring TextEdit preferences..."
  defaults write com.apple.TextEdit RichText -int 0
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
  success_tick_msg "TextEdit preferences configured"

  action_msg "Configuring Disk Utility preferences..."
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true
  success_tick_msg "Disk Utility preferences configured"

  action_msg "Configuring Time Machine preferences..."
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
  success_tick_msg "Time Machine preferences configured"

  info "Configuring Spotlight settings..."
  touch ~/workspace/.metadata_never_index
  sudo mdutil -E /
  success_tick_msg "Spotlight settings configured"

  info "Configuring Console settings..."
  defaults write com.apple.Console DebugMenu -bool true
  defaults write com.apple.Console ShowDeveloperLogs -bool true
  success_tick_msg "Console settings configured"

  info "Configuring screen capture settings..."
  mkdir -p "${HOME}/Pictures/Screenshots"
  defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
  defaults write com.apple.screencapture type -string "png"
  success_tick_msg "Screen capture settings configured"

  info "Configuring Mail application settings"
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
  defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
  success_tick_msg "Mail application settings configured"

  success_tick_msg "App configuration completed"
  summary_msgs+=("✓ Apps: configured")
  return 0
}

configure_macos() {
  local summary_msgs=()

  if ! is_macos; then
    info "Not running on macOS. Skipping all macOS configuration."
    return 0
  fi

  step_header "macOS Configuration"

  info "This script will configure various macOS settings to enhance your experience."
  if ! ui_confirm "Do you want to apply these macOS configurations?"; then
    warning "macOS configuration cancelled."
    return 0
  fi

  if configure_macos_defaults; then
    :
  else
    summary_msgs+=("✗ macOS defaults: failed")
  fi

  if configure_macos_finder; then
    :
  else
    summary_msgs+=("✗ Finder: failed")
  fi

  if configure_macos_dock; then
    :
  else
    summary_msgs+=("✗ Dock: failed")
  fi

  if configure_macos_apps; then
    :
  else
    summary_msgs+=("✗ Apps: failed")
  fi

  if [ ${#summary_msgs[@]} -gt 0 ]; then
    info "Summary:"
    for msg in "${summary_msgs[@]}"; do
      info "$msg"
    done
  fi

  success_tick_msg "macOS configuration completed"
  info "Some changes may require a logout or restart to take effect."
  return 0
}
