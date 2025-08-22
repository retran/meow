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
  ui_step_header "$(get_static_message "system_defaults_header")"

  if ! is_macos; then
    ui_warning "$(get_static_message "macos_not_running_skip")"
    return 0
  fi

  ui_action_start "$(get_static_message "macos_configuring_preferences")"

  osascript -e 'tell application "System Preferences" to quit'

  if ui_confirm "$(get_static_message "computer_name_prompt")"; then
    ui_action_start "$(get_static_message "enter_computer_name")"
    read -r computer_name
    if [[ -n "$computer_name" ]]; then
      sudo scutil --set ComputerName "$computer_name"
      sudo scutil --set HostName "$computer_name"
      sudo scutil --set LocalHostName "$computer_name"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"
      ui_action_success "$(format_template_message "computer_name_set_to" "$computer_name")"
    fi
  fi

  ui_info "$(get_static_message "macos_configuring_brew_path")"
  sudo launchctl config user path "$(brew --prefix)/bin:${PATH}"
  ui_action_success "$(get_static_message "macos_brew_path_configured")"

  ui_info "$(get_static_message "macos_configuring_ui_ux")"
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
  ui_action_success "$(get_static_message "macos_ui_ux_configured")"

  ui_info "$(get_static_message "macos_configuring_keyboard")"
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  ui_action_success "$(get_static_message "macos_keyboard_configured")"

  ui_action_start "$(get_static_message "macos_configuring_input_devices")"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
  ui_action_success "$(get_static_message "macos_input_devices_configured")"

  ui_info "$(get_static_message "macos_configuring_energy")"
  sudo pmset -c displaysleep 15
  sudo pmset -b displaysleep 5
  sudo pmset -b sleep 15
  sudo pmset -c sleep 30
  sudo pmset -a hibernatemode 0
  ui_action_success "$(get_static_message "macos_energy_configured")"

  ui_action_success "$(get_static_message "macos_defaults_configured")"
  summary_msgs+=("✓ macOS defaults: configured")
  return 0
}

configure_macos_finder() {
  ui_step_header "$(get_static_message "macos_finder_configuration")"

  if ! is_macos; then
    ui_warning "$(get_static_message "macos_not_running_finder")"
    return 0
  fi

  ui_action_start "$(get_static_message "macos_configuring_finder")"

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

  ui_action_success "$(get_static_message "macos_finder_configured")"
  summary_msgs+=("✓ Finder: configured")
  return 0
}

configure_macos_dock() {
  ui_step_header "$(get_static_message "macos_dock_configuration")"

  if ! is_macos; then
    ui_warning "$(get_static_message "macos_not_running_dock")"
    return 0
  fi

  ui_action_start "$(get_static_message "macos_configuring_dock")"
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
  ui_action_success "$(get_static_message "macos_dock_configured")"
  summary_msgs+=("✓ Dock: configured")
  return 0
}

configure_macos_apps() {
  ui_step_header "$(get_static_message "macos_app_configuration")"

  if ! is_macos; then
    ui_warning "$(get_static_message "macos_not_running_app")"
    return 0
  fi

  ui_action_start "$(get_static_message "macos_configuring_apps")"

  ui_action_start "$(get_static_message "macos_configuring_photos")"
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
  ui_action_success "$(get_static_message "macos_photos_configured")"

  ui_action_start "$(get_static_message "macos_configuring_textedit")"
  defaults write com.apple.TextEdit RichText -int 0
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
  ui_action_success "$(get_static_message "macos_textedit_configured")"

  ui_action_start "$(get_static_message "macos_configuring_disk_utility")"
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true
  ui_action_success "$(get_static_message "macos_disk_utility_configured")"

  ui_action_start "$(get_static_message "macos_configuring_time_machine")"
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
  ui_action_success "$(get_static_message "macos_time_machine_configured")"

  ui_info "$(get_static_message "macos_configuring_spotlight")"
  touch ~/workspace/.metadata_never_index
  sudo mdutil -E /
  ui_action_success "$(get_static_message "macos_spotlight_configured")"

  ui_info "$(get_static_message "macos_configuring_console")"
  defaults write com.apple.Console DebugMenu -bool true
  defaults write com.apple.Console ShowDeveloperLogs -bool true
  ui_action_success "$(get_static_message "macos_console_configured")"

  ui_info "$(get_static_message "macos_configuring_screen_capture")"
  mkdir -p "${HOME}/Pictures/Screenshots"
  defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
  defaults write com.apple.screencapture type -string "png"
  ui_action_success "$(get_static_message "macos_screen_capture_configured")"

  ui_info "$(get_static_message "macos_configuring_mail")"
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
  defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
  ui_action_success "$(get_static_message "macos_mail_configured")"

  ui_action_success "$(get_static_message "macos_app_configuration_completed")"
  summary_msgs+=("✓ Apps: configured")
  return 0
}

configure_macos() {
  local summary_msgs=()

  if ! is_macos; then
    ui_info "$(get_static_message "macos_not_running_all")"
    return 0
  fi

  ui_step_header "macOS Configuration"

  ui_info "$(get_static_message "macos_config_intro")"
  if ! ui_confirm "$(get_static_message "macos_config_confirmation")"; then
    ui_warning "$(get_static_message "macos_config_cancelled")"
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
    ui_info "$(get_static_message "macos_config_summary")"
    for msg in "${summary_msgs[@]}"; do
      ui_info "$msg"
    done
  fi

  ui_action_success "macOS configuration completed"
  ui_info "$(get_static_message "macos_config_restart_notice")"
  return 0
}
