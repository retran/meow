#!/usr/bin/env bash

# Set strict mode for shell script execution.
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: The return value of a pipeline is the status of the last command to exit with a non-zero status,
#              or zero if all commands in the pipeline exit successfully.

# Source the UI library, which provides functions like ui_step_header, ui_action_start, etc.
# The MEOW variable is expected to be set by the calling environment to point to the base directory.
source "${MEOW}/lib/core/ui.sh"

# Include guard to prevent re-sourcing this script if it's already been sourced.
# This helps maintain state and prevent duplicate function definitions in the same shell session.
if [ "${BASH_SOURCE[0]}" != "${0}" ] && [ -n "${_LIB_SYSTEM_MACOS_SOURCED:-}" ]; then
  return 0
fi
_LIB_SYSTEM_MACOS_SOURCED=1

# is_macos: Checks if the current operating system is macOS.
# Returns 0 if macOS (true), 1 otherwise (false).
is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

# configure_macos_defaults: Configures various system-wide macOS preferences.
# These include general UI/UX, keyboard, input device, and energy saving settings.
configure_macos_defaults() {
  ui_step_header "System Defaults"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping macOS default settings configuration."
    return 0
  fi

  ui_action_start "Applying general macOS system preferences..."

  # Quit System Preferences to ensure changes take effect immediately without conflict.
  # Using '|| true' to prevent 'set -e' from exiting if System Preferences is not running.
  osascript -e 'tell application "System Preferences" to quit' || true

  if ui_confirm "Do you want to set a new computer name?"; then
    ui_info "Enter your desired computer name:"
    read -r computer_name
    if [ -n "$computer_name" ]; then
      sudo scutil --set ComputerName "$computer_name"
      sudo scutil --set HostName "$computer_name"
      sudo scutil --set LocalHostName "$computer_name"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"
      ui_action_success "$(_f "Computer name set to %s" "$computer_name")"
    else
      ui_info "Computer name not set. Skipping."
    fi
  fi

  ui_info "Configuring Homebrew PATH for privileged commands..."
  # Sets the system-wide user PATH for launchd, which affects sudo and other system processes.
  # This ensures brew commands are found by privileged users.
  sudo launchctl config user path "$(brew --prefix)/bin:${PATH}"
  ui_action_success "Homebrew PATH configured."

  ui_info "Applying general UI/UX settings..."
  sudo nvram SystemAudioVolume=" "                                               # Disable startup sound
  defaults write com.apple.finder AppleShowAllFiles -boolean true                # Show hidden files
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true    # Expand save panels by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true   # Expand save panels by default
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true       # Expand print panel by default
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true      # Expand print panel by default
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false    # Save to disk by default, not iCloud
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true   # Quit printer app once the print jobs complete
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false     # Disable automatic capitalization
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false   # Disable smart dashes
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false # Disable automatic period substitution
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # Disable smart quotes
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false # Disable automatic spell correction
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001                  # Accelerate window resizing
  ui_action_success "General UI/UX settings applied."

  ui_info "Applying keyboard settings..."
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false # Disable press-and-hold for special characters in favor of key repeat
  defaults write NSGlobalDomain KeyRepeat -int 1                     # Fastest key repeat rate
  defaults write NSGlobalDomain InitialKeyRepeat -int 15             # Shortest delay until key repeat starts
  ui_action_success "Keyboard settings applied."

  ui_action_start "Applying input device settings..."
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true # Enable tap to click for trackpad
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1         # Enable tap to click for trackpad (current host)
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1                      # Enable tap to click for trackpad (global)
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40   # Improve Bluetooth audio quality
  ui_action_success "Input device settings applied."

  ui_info "Applying energy saving settings..."
  sudo pmset -c displaysleep 15 # Display sleep after 15 minutes on AC power
  sudo pmset -b displaysleep 5  # Display sleep after 5 minutes on battery
  sudo pmset -b sleep 15        # Computer sleep after 15 minutes on battery
  sudo pmset -c sleep 30        # Computer sleep after 30 minutes on AC power
  sudo pmset -a hibernatemode 0 # Disable hibernation (faster boot, more power usage when off)
  ui_action_success "Energy saving settings applied."

  ui_action_success "macOS system defaults configured."
  summary_msgs+=("✓ macOS defaults: configured")
  return 0
}

# configure_macos_finder: Configures various settings for Finder.
configure_macos_finder() {
  ui_step_header "Finder Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping Finder configuration."
    return 0
  fi

  ui_action_start "Applying Finder preferences..."

  # Quit Finder to ensure changes take effect immediately without conflict.
  # Using '|| true' to prevent 'set -e' from exiting if Finder is not running.
  osascript -e 'tell application "Finder" to quit' || true

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true            # Show all filename extensions
  defaults write com.apple.finder ShowPathbar -bool true                     # Show path bar
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"        # Set default view style to list view ('Nlsv')
  defaults write com.apple.finder _FXSortFoldersFirst -bool true             # Keep folders on top when sorting by name
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"        # Search the current folder by default
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable the warning when changing a file extension
  defaults write com.apple.finder QuitMenuItem -bool false                   # Remove "Quit Finder" from the menu (Finder cannot be truly quit)

  defaults write NSGlobalDomain com.apple.springing.enabled -bool true         # Enable spring loading for all apps
  defaults write NSGlobalDomain com.apple.springing.delay -float 0             # Set spring loading delay to zero
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Disable creation of .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true     # Disable creation of .DS_Store files on USB volumes

  # Show item info (file size, date modified) in icon view for desktop, standard views, and FK_StandardViewSettings.
  /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist"
  /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist"
  /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" "${HOME}/Library/Preferences/com.apple.finder.plist"

  chflags nohidden "${HOME}/Library" # Show the user's Library folder
  sudo chflags nohidden /Volumes     # Show the /Volumes folder

  open -a Finder # Relaunch Finder to apply changes

  ui_action_success "Finder configured."
  summary_msgs+=("✓ Finder: configured")
  return 0
}

# configure_macos_dock: Configures various settings for the Dock.
configure_macos_dock() {
  ui_step_header "Dock Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping Dock configuration."
    return 0
  fi

  ui_action_start "Applying Dock preferences..."
  defaults write com.apple.dock tilesize -int 48                                   # Set icon size
  defaults write com.apple.dock minimize-to-application -bool true                 # Minimize windows into their application icon
  defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true # Enable spring loading for all Dock items
  defaults write com.apple.dock show-process-indicators -bool true                 # Show indicator lights for open applications
  defaults write com.apple.dock expose-animation-duration -float 0.1               # Speed up mission control animations
  defaults write com.apple.dock expose-group-by-app -bool false                    # Do not group windows by application in Mission Control
  defaults write com.apple.dock mru-spaces -bool false                             # Disable rearranging spaces based on recent use
  defaults write com.apple.dock autohide-delay -float 0                            # Remove the auto-hide Dock delay
  defaults write com.apple.dock autohide -bool true                                # Automatically hide and show the Dock
  defaults write com.apple.dock showhidden -bool true                              # Show indicator for hidden applications
  defaults write com.apple.dock show-recents -bool false                           # Do not show recent applications in the Dock
  # Restart Dock to apply changes. Using '|| true' to prevent 'set -e' from exiting if Dock is not running.
  killall Dock || true
  ui_action_success "Dock configured."
  summary_msgs+=("✓ Dock: configured")
  return 0
}

# configure_macos_apps: Configures preferences for various macOS applications.
configure_macos_apps() {
  ui_step_header "App Configuration"

  if ! is_macos; then
    ui_warning "Not running on macOS. Skipping application configuration."
    return 0
  fi

  ui_action_start "Applying macOS application preferences..."

  ui_action_start "Applying Photos application preferences..."
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true # Prevent Photos from opening automatically when devices are connected
  ui_action_success "Photos application preferences applied."

  ui_action_start "Applying TextEdit application preferences..."
  defaults write com.apple.TextEdit RichText -int 0                  # Use plain text mode by default
  defaults write com.apple.TextEdit PlainTextEncoding -int 4         # Set default encoding to UTF-8 (4)
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4 # Set default encoding for saving to UTF-8 (4)
  ui_action_success "TextEdit application preferences applied."

  ui_action_start "Applying Disk Utility preferences..."
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true     # Enable the Debug menu
  defaults write com.apple.DiskUtility advanced-image-options -bool true # Enable advanced image options
  ui_action_success "Disk Utility preferences applied."

  ui_action_start "Applying Time Machine preferences..."
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true # Prevent Time Machine from prompting to use new disks for backup
  ui_action_success "Time Machine preferences applied."

  ui_action_start "Applying Spotlight settings..."
  # Create a file to prevent indexing of the 'workspace' directory if it exists.
  # If ~/workspace does not exist, 'touch' will create the file directly in HOME.
  touch "${HOME}/workspace/.metadata_never_index"
  sudo mdutil -E / # Erase and rebuild Spotlight index for the boot volume
  ui_action_success "Spotlight settings applied."

  ui_action_start "Applying Console application settings..."
  defaults write com.apple.Console DebugMenu -bool true         # Enable the Debug menu
  defaults write com.apple.Console ShowDeveloperLogs -bool true # Show Developer Logs
  ui_action_success "Console application settings applied."

  ui_action_start "Applying screen capture settings..."
  mkdir -p "${HOME}/Pictures/Screenshots"                                                # Ensure screenshots directory exists
  defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots" # Save screenshots to a specific folder
  defaults write com.apple.screencapture type -string "png"                              # Save screenshots as PNGs
  ui_action_success "Screen capture settings applied."

  ui_action_start "Applying Mail application settings..."
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false # Copy email addresses as 'foo@example.com' instead of 'Foo Bar <foo@example.com>'
  defaults write com.apple.mail DisableInlineAttachmentViewing -bool true    # Prevent attachments from showing inline
  ui_action_success "Mail application settings applied."

  ui_action_success "macOS application configuration completed."
  summary_msgs+=("✓ Apps: configured")
  return 0
}

# configure_macos: Main function to orchestrate macOS configuration.
# Calls sub-functions to configure defaults, Finder, Dock, and applications.
configure_macos() {
  local summary_msgs=() # Initialize local array to collect summary messages

  if ! is_macos; then
    ui_info "Not running on macOS. Skipping all macOS configuration steps."
    return 0
  fi

  ui_step_header "macOS Configuration"

  ui_info "This script will configure various macOS settings to enhance your experience."
  if ! ui_confirm "Do you want to apply these macOS configurations?"; then
    ui_warning "macOS configuration cancelled by user."
    return 0
  fi

  # Call configuration functions and record their success or failure.
  if configure_macos_defaults; then
    : # No-op on success
  else
    summary_msgs+=("✗ macOS defaults: failed")
  fi

  if configure_macos_finder; then
    : # No-op on success
  else
    summary_msgs+=("✗ Finder: failed")
  fi

  if configure_macos_dock; then
    : # No-op on success
  else
    summary_msgs+=("✗ Dock: failed")
  fi

  if configure_macos_apps; then
    : # No-op on success
  else
    summary_msgs+=("✗ Apps: failed")
  fi

  # Display a summary of configuration results if there were any issues.
  if [ "${#summary_msgs[@]}" -gt 0 ]; then
    ui_info "--- Configuration Summary ---"
    for msg in "${summary_msgs[@]}"; do
      ui_info "$msg"
    done
    ui_warning "Some macOS configurations failed or encountered issues."
  fi

  ui_action_success "macOS configuration process completed."
  ui_info "Please note: Some changes may require a logout or restart to take effect."
  return 0
}
