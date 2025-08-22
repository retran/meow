#!/usr/bin/env bash

# lib/strings/strings.sh - Unified strings file with modular structure

if [[ -n "${_LIB_STRINGS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_SOURCED=1

declare -A UI_MESSAGES=(
  # General operations
  ["session_init_failed"]="Session initialization failed"
  ["installation_order"]="Installation order:"
  ["update_order"]="Update order:"
  ["uninstall_order"]="Uninstall order:"
  ["no_components_to_install"]="No components to install"
  ["no_components_to_update"]="No components to update"
  ["all_components_installed"]="All components already installed"

  # System setup
  ["available_presets"]="Available Presets"
  ["updating_all_components"]="Updating all installed components"
  ["no_components_installed"]="No components are currently installed"
  ["zsh_setup_issues"]="Zsh environment setup encountered issues"
  ["tmux_setup_issues"]="tmux environment setup encountered issues"

  # Status messages
  ["already_installed"]="already installed"
  ["up_to_date"]="up-to-date"
  ["already_correct"]="already correct"
  ["not_installed"]="not installed"
  ["incompatible"]="incompatible"
  ["available"]="available"
  ["installed"]="installed"
  ["installed_manual"]="installed (manual)"

  # Confirmation
  ["confirm_default"]="Confirm"

  # Commands and errors
  ["command_output"]="Command output:"
  ["command_failed_first_lines"]="Command failed. First few lines of output:"

  # Component operations
  ["component_setup_completed"]="Component setup completed successfully"
  ["component_setup_failed"]="Component setup failed"
  ["component_cleanup_completed"]="Component cleanup completed successfully"
  ["component_cleanup_failed"]="Component cleanup failed"

  # tmux system setup
  ["tmux_not_installed_skip_plugin"]="tmux is not installed, skipping Plugin Manager setup"
  ["tmux_setting_up_plugin_manager"]="Setting up tmux Plugin Manager"
  ["tmux_plugin_manager_already_installed"]="tmux Plugin Manager is already installed."
  ["tmux_updating_plugin_manager"]="Updating tmux Plugin Manager"
  ["tmux_plugin_manager_update_completed"]="tmux Plugin Manager update completed"
  ["tmux_plugin_manager_update_failed"]="Failed to update tmux Plugin Manager"
  ["tmux_installing_plugin_manager"]="Installing tmux Plugin Manager"
  ["tmux_plugin_manager_install_completed"]="tmux Plugin Manager installation completed"
  ["tmux_plugin_manager_install_failed"]="Failed to install tmux Plugin Manager"
  ["tmux_setting_up_environment"]="Setting up tmux environment"
  ["tmux_environment_setup_complete"]="tmux environment setup complete."

  # zsh system setup
  ["zsh_checking_ohmyzsh"]="Checking for Oh My Zsh installation..."
  ["zsh_ohmyzsh_already_installed"]="Oh My Zsh is already installed."
  ["zsh_updating_ohmyzsh"]="Updating Oh My Zsh"
  ["zsh_ohmyzsh_update_completed"]="Oh My Zsh update completed"
  ["zsh_ohmyzsh_update_failed"]="Failed to update Oh My Zsh"
  ["zsh_installing_ohmyzsh"]="Installing Oh My Zsh"
  ["zsh_ohmyzsh_install_completed"]="Oh My Zsh installation completed"
  ["zsh_ohmyzsh_install_failed"]="Failed to install Oh My Zsh"
  ["zsh_setting_up_environment"]="Setting up Zsh environment"
  ["zsh_environment_setup_complete"]="Zsh environment setup complete."

  # System setup
  ["motd_system_territory"]="Let me tell you about your digital territory, comrade:"

  # Rust system setup
  ["rust_version_info"]="Rust version: %s"

  # macOS keyboard configuration
  ["macos_system_defaults"]="System Defaults"
  ["macos_finder_config"]="Finder Configuration"
  ["macos_dock_config"]="Dock Configuration"
  ["macos_app_config"]="App Configuration"
  ["macos_configuration"]="macOS Configuration"

  # Node.js component setup
  ["node_npm_not_found_skip"]="npm command not found. Skipping Node.js configuration"
  ["node_configuring_global_packages"]="Configuring npm for global packages without sudo"
  ["node_npm_configured_successfully"]="NPM configured successfully"

  # Component cleanup - Rust Development
  ["rust_dev_cleanup_running"]="🧹 Running Rust Development cleanup..."
  ["rust_dev_cleaning_cargo_cache"]="  📦 Cleaning cargo cache..."
  ["rust_dev_cleaning_registry_cache"]="  🗑️  Cleaning cargo registry cache..."
  ["rust_dev_cleaning_git_cache"]="  🗑️  Cleaning cargo git cache..."
  ["rust_dev_cleaning_target_dirs"]="  🗑️  Cleaning Rust target directories..."
  ["rust_dev_cleaning_rustup_temp"]="  🗑️  Cleaning rustup temporary files..."
  ["rust_dev_cleanup_completed"]="✅ Rust Development cleanup completed"

  # Component cleanup - Python Development
  ["python_dev_cleanup_running"]="🧹 Running Python Development cleanup..."
  ["python_dev_cleaning_pip_cache"]="  📦 Cleaning pip cache..."
  ["python_dev_cleaning_pip3_cache"]="  📦 Cleaning pip3 cache..."
  ["python_dev_cleaning_bytecode"]="  🗑️  Cleaning Python bytecode files..."
  ["python_dev_removing_pytest_cache"]="  🗑️  Removing pytest cache..."
  ["python_dev_removing_mypy_cache"]="  🗑️  Removing mypy cache..."
  ["python_dev_cleaning_ipython_cache"]="  🗑️  Cleaning IPython cache..."
  ["python_dev_cleanup_completed"]="✅ Python Development cleanup completed"

  # Component cleanup - Gaming
  ["gaming_cleanup_running"]="🧹 Running Gaming cleanup..."
  ["gaming_stopping_steam"]="  ⏹️  Stopping Steam..."
  ["gaming_stopping_geforce_now"]="  ⏹️  Stopping NVIDIA GeForce NOW..."
  ["gaming_removing_login_items"]="  🗑️  Removing gaming apps from login items..."
  ["gaming_cleaning_cache"]="  🗑️  Cleaning gaming cache and logs..."
  ["gaming_cleanup_completed"]="✅ Gaming cleanup completed"
  ["gaming_saves_preserved"]="ℹ️  Note: Game saves and user data were preserved"

  # Desktop Essential component setup
  ["desktop_essential_macos_config_complete"]="macOS configuration complete (may require logout/restart)"
  ["desktop_essential_macos_config_issues"]="macOS configuration encountered issues or was skipped"

  # Shell Essential component setup
  ["shell_essential_configuring_tmux"]="Configuring tmux"
  ["shell_essential_configuring_zsh"]="Configuring zsh"

  ["tmux_setup_issues"]="tmux environment setup encountered issues"

  # Status messages
  ["already_installed"]="already installed"
  ["up_to_date"]="up-to-date"
  ["already_correct"]="already correct"
  ["not_installed"]="not installed"
  ["incompatible"]="incompatible"
  ["available"]="available"
  ["installed"]="installed"
  ["installed_manual"]="installed (manual)"

  # Confirmation
  ["confirm_default"]="Confirm"

  # Commands and errors
  ["command_output"]="Command output:"
  ["command_failed_first_lines"]="Command failed. First few lines of output:"

  # Component operations
  ["component_setup_completed"]="Component setup completed successfully"
  ["component_setup_failed"]="Component setup failed"
  ["component_cleanup_completed"]="Component cleanup completed successfully"
  ["component_cleanup_failed"]="Component cleanup failed"
  ["component_tracking_removed"]="Component tracking removed"
  ["requested_components"]="Requested components: %s"
  ["new_dependencies"]="New dependencies: %s"

  # Component operation messages
  ["installing_component"]="Installing component: %s"
  ["component_installed"]="Component installed: %s"
  ["updating_component"]="Updating component: %s"
  ["component_updated"]="Component updated: %s"
  ["uninstalling_component"]="Uninstalling component: %s"
  ["component_uninstalled"]="Component uninstalled: %s"
  ["setting_up_component"]="Setting up component: %s"
  ["cleaning_component"]="Cleaning component: %s"

  # Component count messages
  ["components_install_count"]="Will install %d component%s with dependencies"
  ["total_components_install"]="Total components to install: %d"

  # Symlinks operations
  ["symlinks_configuration_checked"]="Symlinks: ✓ %d configuration%s checked"

  # Package installation messages
  ["package_not_installed_skipping"]="Package not installed, skipping: %s"
  ["package_already_installed"]="Package already installed: %s"
  ["installing_package"]="Installing %s"
  ["successfully_installed_package"]="Successfully installed %s"
  ["failed_to_install_package"]="Failed to install %s"
  ["updating_package"]="Updating %s"
  ["successfully_updated_package"]="Successfully updated %s"
  ["failed_to_update_package"]="Failed to update %s"
  ["uninstalling_package"]="Uninstalling %s"
  ["successfully_uninstalled_package"]="Successfully uninstalled %s"
  ["failed_to_uninstall_package"]="Failed to uninstall %s"
  ["silent_spinner_installing"]="Installing %s %s"
  ["silent_spinner_updating"]="Updating %s %s"
  ["silent_spinner_checking"]="Checking %s %s"
  ["silent_spinner_uninstalling"]="Uninstalling %s %s"

  # Additional UI template messages
  ["command_more_lines_hidden"]="%d more lines hidden..."
  ["setting_up_package_manager"]="Setting up %s package manager"
  ["manager_ready"]="%s package manager ready"
  ["cleaning_package_manager"]="Cleaning %s package manager"
  ["manager_cleanup_completed"]="%s package manager cleanup completed"
  ["installing_packages"]="Installing packages for %s"
  ["updating_packages"]="Updating packages for %s"
  ["package_manager_removal"]="Removing %s packages for %s"
  ["removing_repo"]="Removing repository for %s"
  ["cloning_repo"]="Cloning repository for %s"
  ["updating_repo"]="Updating repository for %s"
  ["cleaning_repo"]="Cleaning repository for %s"
  ["repo_cleaned_for"]="Repository cleaned for %s"
  ["setting_up_symlinks"]="Setting up symlinks for %s"
  ["removing_symlinks"]="Removing symlinks for %s"
  ["symlinks_configured"]="Symlinks configured for %s"
  ["symlinks_removed"]="Symlinks removed for %s"

  # MOTD template messages
  ["motd_greeting"]="%s, сomrade %s!"
  ["motd_greeting_comrade"]="%s, сomrade %s!"
  ["motd_calendar"]="Calendar shows %s."
  ["motd_calendar_shows"]="Calendar shows %s"
  ["motd_clock"]="Clock purrs at %s."
  ["motd_clock_purrs"]="Clock purrs at %s"
  ["motd_ascii_art_not_found"]="ASCII art file not found: %s"
  ["motd_system_info"]="System:     %s"
  ["motd_shell_info"]="Shell:      %s"
  ["motd_uptime_info"]="Uptime:     %s"
  ["motd_disk_info"]="Disk:       %s"
  ["motd_ram_info"]="RAM:        %s"
  ["motd_updates_info"]="Updates:    %s packages need updating"
  ["motd_computer_name_set"]="Computer name set to %s"

  # macOS template messages
  ["macos_keyboard_unknown_layout_type"]="Unknown layout type: %s. Use 'das' or 'mbp'"
  ["macos_keyboard_configuring_layouts"]="Configuring keyboard layouts for %s..."
  ["macos_keyboard_layouts_configured"]="Keyboard layouts configured for %s"
  ["macos_setting_computer_name"]="Computer name set to %s"

  # Repository operations
  ["repo_updated"]="Repository updated successfully"
  ["repo_cleaned"]="Repository cleaned up"

  # Package operations
  ["packages_updated"]="Packages updated successfully"
  ["packages_uninstalled"]="Packages uninstalled successfully"
  ["package_updates_failed"]="Some package updates may have failed"
  ["package_uninstall_failed"]="Some package uninstallation may have failed"

  # Package manager summary messages
  ["package_summary_success_installed"]="%s: ✓ %d installed, %d already present"
  ["package_summary_success_present"]="%s: ✓ %d/%d already present"
  ["package_summary_success_updated"]="%s: ✓ %d updated, %d up-to-date"
  ["package_summary_success_up_to_date"]="%s: ✓ %d/%d up-to-date"
  ["package_summary_success_uninstalled"]="%s: ✓ %d uninstalled, %d not installed"
  ["package_summary_success_not_installed"]="%s: ✓ %d/%d not installed"
  ["package_summary_failed_install"]="%s: ✗ %d failed, %d installed, %d already present"
  ["package_summary_failed_update"]="%s: ✗ %d failed, %d updated, %d up-to-date"
  ["package_summary_failed_uninstall"]="%s: ✗ %d failed, %d uninstalled, %d not installed"

  # Symlinks operations
  ["symlinks_restored"]="Symlinks removed and backups restored successfully"

  # Package managers
  ["npm_not_found"]="npm not found"
  ["npm_not_found_would_fail"]="npm not found - would fail setup"
  ["npm_already_available"]="npm already available, no setup needed"
  ["npm_cleaning_cache"]="Cleaning npm cache"
  ["go_not_found"]="Go not found"
  ["go_not_found_would_fail"]="Go not found - would fail setup"
  ["go_already_available"]="Go already available, ready for package installation"
  ["go_available"]="Go available"
  ["go_setting_up"]="Setting up Go"
  ["go_package_removal_header"]="Go Package Removal (%s)"
  ["go_packages_cannot_uninstall"]="Go packages cannot be automatically uninstalled via go command"
  ["go_packages_manual_removal"]="Go packages are installed to GOPATH/bin. Please manually remove binaries if needed:"
  ["go_cleanup_would_skip"]="Go cleanup would be skipped (no cleanup needed)"
  ["go_modules_managed_by_go"]="Go modules are cached in GOMODCACHE, managed by Go itself"
  ["go_cleaning_noop"]="Cleaning Go (no-op)"
  ["go_cleanup_skipped"]="Go cleanup skipped"
  ["cargo_not_found"]="cargo not found"
  ["cargo_not_found_would_fail"]="cargo not found - would fail setup"
  ["cargo_already_available"]="Cargo already available, ready for package installation"
  ["cargo_available"]="Cargo available"
  ["cargo_setting_up"]="Setting up Cargo"
  ["cargo_cleanup_would_skip"]="Cargo cleanup would be skipped (no cleanup needed)"
  ["cargo_packages_managed_by_toolchain"]="Cargo packages are installed per-user, managed by Rust toolchain"
  ["cargo_cleaning_noop"]="Cleaning Cargo (no-op)"
  ["cargo_cleanup_skipped"]="Cargo cleanup skipped"
  ["apt_get_not_found"]="apt-get not found - would fail setup"
  ["apt_would_update_index"]="Would update APT package index"
  ["apt_update_command"]="Command: sudo apt-get update"
  ["apt_would_refresh_info"]="Would refresh available package information"
  ["apt_updating_index"]="Updating APT index"
  ["apt_index_updated"]="APT index updated"
  ["apt_index_update_failed"]="Failed to update APT index"
  ["apt_would_clean_cache"]="Would clean APT package cache and remove unused packages"
  ["apt_cleanup_commands"]="Commands: sudo apt-get autoremove -y && sudo apt-get clean"
  ["apt_would_remove_orphaned"]="Would remove orphaned packages and clear download cache"
  ["vscode_setting_up"]="Setting up VS Code CLI"
  ["vscode_cli_not_found_would_warn"]="VS Code CLI not found - would warn and skip extensions"
  ["vscode_cli_already_available"]="VS Code CLI already available, ready for extension installation"
  ["vscode_cli_not_found_skip"]="VS Code CLI not found, skipping extensions"
  ["vscode_cli_available"]="VS Code CLI available"
  ["vscode_cli_not_found_extension_skip"]="VS Code CLI not found, skipping VS Code extension installation"
  ["vscode_cleaning"]="Cleaning VS Code"
  ["tmux_not_installed_skip_plugin"]="tmux is not installed, skipping Plugin Manager setup"
  ["tmux_setting_up_plugin_manager"]="Setting up tmux Plugin Manager"
  ["tmux_plugin_manager_already_installed"]="tmux Plugin Manager is already installed."
  ["tmux_updating_plugin_manager"]="Updating tmux Plugin Manager"
  ["tmux_plugin_manager_update_completed"]="tmux Plugin Manager update completed"
  ["tmux_plugin_manager_update_failed"]="Failed to update tmux Plugin Manager"
  ["tmux_installing_plugin_manager"]="Installing tmux Plugin Manager"
  ["tmux_plugin_manager_install_completed"]="tmux Plugin Manager installation completed"
  ["tmux_plugin_manager_install_failed"]="Failed to install tmux Plugin Manager"
  ["tmux_setting_up_environment"]="Setting up tmux environment"
  ["tmux_environment_setup_complete"]="tmux environment setup complete."
  ["zsh_checking_ohmyzsh"]="Checking for Oh My Zsh installation..."
  ["zsh_ohmyzsh_already_installed"]="Oh My Zsh is already installed."
  ["zsh_updating_ohmyzsh"]="Updating Oh My Zsh"
  ["zsh_ohmyzsh_update_completed"]="Oh My Zsh update completed"
  ["zsh_ohmyzsh_update_failed"]="Failed to update Oh My Zsh"
  ["zsh_installing_ohmyzsh"]="Installing Oh My Zsh"
  ["zsh_ohmyzsh_install_completed"]="Oh My Zsh installation completed"
  ["zsh_ohmyzsh_install_failed"]="Failed to install Oh My Zsh"
  ["zsh_setting_up_environment"]="Setting up Zsh environment"
  ["zsh_environment_setup_complete"]="Zsh environment setup complete."
  ["pipx_setting_up"]="Setting up pipx"
  ["pipx_not_found_would_fail"]="pipx not found - would fail setup"
  ["pipx_already_available"]="pipx already available, no setup needed"
  ["pipx_not_found"]="pipx not found"
  ["pipx_available"]="pipx available"
  ["pipx_cleaning"]="Cleaning pipx"
  ["apk_setting_up"]="Setting up apk"
  ["apk_not_found_would_fail"]="apk not found - would fail setup"
  ["apk_would_update_index"]="Would update apk package index"
  ["apk_update_command"]="Command: sudo apk update"
  ["apk_would_refresh_info"]="Would refresh available package information"
  ["apk_not_found"]="apk not found"
  ["apk_failed_update"]="Failed to update apk package index"
  ["apk_setup_complete"]="apk available"
  ["apk_cleanup_would_skip"]="apk cleanup would be skipped (no cache to clean)"
  ["apk_no_cache_info"]="apk uses --no-cache flag so no cleanup needed"
  ["apk_cleaning"]="Cleaning apk"
  ["apk_cleanup_completed"]="apk cleanup completed (no cache to clean)"
  ["apk_cleanup_completed_short"]="apk cleanup completed"

  # pacman (Arch Linux)
  ["pacman_setting_up"]="Setting up pacman"
  ["pacman_not_found_would_fail"]="pacman not found - would fail setup"
  ["pacman_would_sync_db"]="Would sync pacman package database"
  ["pacman_sync_command"]="Command: sudo pacman -Sy"
  ["pacman_would_refresh_info"]="Would refresh available package information"
  ["pacman_not_found"]="pacman not found"
  ["pacman_failed_sync"]="Failed to sync pacman database"
  ["pacman_setup_complete"]="pacman ready"
  ["pacman_would_clean_cache"]="Would clean pacman package cache"
  ["pacman_clean_command"]="Command: sudo pacman -Sc --noconfirm"
  ["pacman_would_remove_cached"]="Would remove cached packages not currently installed"
  ["pacman_cleaning"]="Cleaning pacman"

  # Components - packages
  ["component_dir_not_found"]="Component directory not found: %s"
  ["installing_packages_for"]="Installing packages for %s"
  ["packages_errors_occurred"]="Packages: ✗ %d errors occurred"
  ["update_function_not_found"]="Update function %s not found."
  ["updating_packages_for"]="Updating packages for %s"

  # Components - repository
  ["removing_existing_repo"]="Removing existing repository for component: %s"
  ["cloning_repo_to_downloads"]="Cloning repository to .downloads/%s"
  ["repository_not_found_cloning"]="Repository not found, cloning to .downloads/%s instead"
  ["updating_repo_for_component"]="Updating repository for component: %s"
  ["failed_update_trying_reclone"]="Failed to update repository, trying to re-clone"
  ["cleaning_up_repo"]="Cleaning up repository for %s"
  ["failed_remove_repo_dir"]="Failed to remove repository directory: %s"
  ["repo_cleaned_up"]="Repository cleaned up for %s"
  ["failed_update_trying_reclone"]="Failed to update repository, trying to re-clone"

  # Components - symlinks
  ["setting_up_symlinks_for"]="Setting up symlinks for component: %s"

  # MOTD (Message of the Day)
  ["motd_meow_not_set"]="Error: MEOW environment variable is not set."
  ["motd_yq_not_installed"]="Warning: 'yq' is not installed. Cannot display random comments."

  # System configuration
  ["system_defaults_header"]="System Defaults"
  ["macos_not_running_skip"]="Not running on macOS. Skipping macOS configuration."
  ["computer_name_set_to"]="Computer name set to %s"
  ["checking_zsh_plugins"]="Checking Zsh plugins..."
  ["zsh_plugins_checked_installed"]="Zsh plugins checked/installed"
  ["oh_my_zsh_dir_not_found"]="Oh My Zsh dir not found at '%s'. Skipping plugins"
  ["macos_keyboard_only_works_macos"]="macOS keyboard layout configuration only works on macOS"
  ["restoring_active_russian_layout"]="Restoring active Russian layout..."

  # Dry run operations
  ["dry_run_install_packages"]="Would install %s packages: %s"
  ["dry_run_update_packages"]="Would update %s packages: %s"
  ["dry_run_remove_packages"]="Would remove %s packages: %s"
  ["dry_run_perform_operation"]="Would perform %s operation '%s' on packages: %s"
  ["dry_run_clone_repository"]="Would clone repository to: %s"
  ["dry_run_repository_url"]="Repository URL: %s"
  ["dry_run_pull_updates"]="Would pull updates in repository: %s"
  ["dry_run_checkout"]="Would checkout '%s' in repository: %s"
  ["dry_run_git_operation"]="Would perform git operation '%s' in: %s"

  # Presets
  ["preset_not_found"]="Preset '%s' not found"
  ["preset_not_available_platform"]="Preset '%s' is not available on this platform"
  ["preset_already_installed"]="Preset '%s' is already installed"
  ["installing_preset"]="==> Installing Preset: %s"
  ["no_components_to_install_preset"]="No components to install for this preset"
  ["will_install_preset_components"]="Will install %d preset components with dependencies"
  ["total_components_to_install"]="Total components to install: %d"
  ["preset_components_list"]="Preset components: %s"
  ["dependencies_list"]="Dependencies: %s"
  ["failed_install_required_components"]="Failed to install required components"
  ["preset_not_installed"]="Preset '%s' is not installed"
  ["updating_preset"]="Updating preset: %s"
  ["updating_required_components"]="Updating required components"
  ["required_component_not_installed"]="Required component '%s' not installed, skipping"
  ["found_installed_components"]="Found %d installed components: %s"
  ["available_presets"]="Available Presets"

  # Symlinks
  ["symlink_skip_source_missing"]="Would skip symlink (source does not exist): %s -> %s"
  ["symlink_source_missing"]="Source %s does not exist. Skipping symlink for %s"
  ["symlink_already_correct"]="Symlink already correct: %s -> %s"
  ["symlink_update"]="Would update symlink: %s -> %s"
  ["symlink_current_target"]="Current target: %s"
  ["symlink_backup_and_create"]="Would backup existing file and create symlink: %s -> %s"
  ["symlink_create_new"]="Would create new symlink: %s -> %s"
  ["symlink_parent_dir_failed"]="Failed to create parent directory for %s."
  ["symlink_remove_failed"]="Failed to remove existing symlink at %s."
  ["symlink_backed_up"]="%s (backed up to %s)"
  ["symlink_backup_failed"]="Failed to backup existing file at %s."
  ["symlink_created"]="%s (created)"
  ["symlink_create_failed"]="Failed to create symlink: %s -> %s"
  ["yq_required"]="yq is required to parse symlink configuration. Please install yq."
  ["yq_already_installed"]="⇒ yq %s is already installed."
  ["yq_version_mismatch"]="Found yq, but version mismatch. Expected: '%s', Found: '%s'"
  ["yq_installing"]="Installing yq v%s..."
  ["yq_unsupported_os"]="Unsupported OS: %s"
  ["yq_unsupported_arch"]="Unsupported architecture: %s"
  ["yq_installed_successfully"]="yq v%s installed to %s"
  ["yq_download_failed"]="Failed to download yq from %s"
  ["no_symlinks_file"]="No symlinks file found for '%s' at %s"
  ["no_symlinks_defined"]="No symlinks defined in %s."
  ["symlinks_processed_count"]="(%d symlinks processed for this OS)"
  ["symlinks_completed"]="Symlinks for '%s' completed (%ss)"
  ["symlinks_failed"]="Symlinks for '%s' failed with %d failure(s) (%ss)"
  ["apk_updating_index"]="Updating apk index"
  ["apk_index_updated"]="apk index updated"
  ["apk_index_update_failed"]="Failed to update apk index"
  ["mas_not_found"]="mas CLI not found"
  ["mas_not_found_would_fail"]="mas CLI not found - would warn and fail setup"
  ["mas_already_available"]="mas CLI already available, no setup needed"
  ["mas_cli_available"]="mas CLI available"
  ["mas_setting_up"]="Setting up mas CLI"
  ["homebrew_not_found"]="Homebrew not found. Installing..."
  ["homebrew_already_available"]="Homebrew already available, no setup needed"
  ["homebrew_install_script_url"]="Script URL: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  ["homebrew_would_install"]="Would install Homebrew using official installation script"
  ["homebrew_would_configure"]="Would configure shell environment after installation"
  ["homebrew_would_clean_cache"]="Would clean Homebrew cache and unused packages"
  ["homebrew_cleanup_command"]="Command: brew cleanup --prune=all"
  ["homebrew_would_remove_outdated"]="Would remove outdated downloads and old package versions"

  # Dry-run mode
  ["dry_run_prefix"]="[DRY-RUN]"

  # macOS specific
  ["macos_config_only"]="macOS keyboard layout configuration only works on macOS"
  ["not_running_macos"]="Not running on macOS. Skipping macOS configuration."
  ["not_running_macos_finder"]="Not running on macOS. Skipping Finder configuration."
  ["computer_name_prompt"]="Do you want to set a new computer name?"
  ["enter_computer_name"]="Enter your desired computer name: "
  ["macos_configuring_preferences"]="Configuring macOS preferences"
  ["macos_configuring_brew_path"]="Configuring brew PATH..."
  ["macos_brew_path_configured"]="brew PATH configured"
  ["macos_configuring_ui_ux"]="Configuring general UI/UX settings..."
  ["macos_ui_ux_configured"]="General UI/UX settings configured"
  ["macos_configuring_keyboard"]="Configuring keyboard settings..."
  ["macos_keyboard_configured"]="Keyboard settings configured"
  ["macos_configuring_input_devices"]="Configuring input device settings..."
  ["macos_input_devices_configured"]="Input device settings configured"
  ["macos_configuring_energy"]="Configuring energy saving settings..."
  ["macos_energy_configured"]="Energy saving settings configured"
  ["macos_defaults_configured"]="System defaults configured"
  ["macos_configuring_finder"]="Configuring Finder preferences"
  ["macos_finder_configured"]="Finder configured"
  ["macos_configuring_dock"]="Configuring Dock preferences"
  ["macos_dock_configured"]="Dock configured"
  ["macos_finder_configuration"]="Finder Configuration"
  ["macos_dock_configuration"]="Dock Configuration"
  ["macos_app_configuration"]="App Configuration"
  ["macos_configuring_apps"]="Configuring macOS application preferences"
  ["macos_configuring_photos"]="Configuring Photos preferences..."
  ["macos_photos_configured"]="Photos preferences configured"
  ["macos_configuring_textedit"]="Configuring TextEdit preferences..."
  ["macos_textedit_configured"]="TextEdit preferences configured"
  ["macos_configuring_disk_utility"]="Configuring Disk Utility preferences..."
  ["macos_disk_utility_configured"]="Disk Utility preferences configured"
  ["macos_configuring_time_machine"]="Configuring Time Machine preferences..."
  ["macos_time_machine_configured"]="Time Machine preferences configured"
  ["macos_configuring_spotlight"]="Configuring Spotlight..."
  ["macos_spotlight_configured"]="Spotlight settings configured"
  ["macos_configuring_console"]="Configuring Console..."
  ["macos_console_configured"]="Console settings configured"
  ["macos_configuring_screen_capture"]="Configuring screen capture..."
  ["macos_screen_capture_configured"]="Screen capture settings configured"
  ["macos_configuring_mail"]="Configuring Mail..."
  ["macos_mail_configured"]="Mail application settings configured"
  ["macos_app_configuration_completed"]="App configuration completed"

  # MOTD fallbacks
  ["motd_fallback"]="A fancy digital cat comment should be here"
  ["motd_greeting_default"]="Meowvelous day"
  ["motd_time_fallback"]="Hope you have a purr-ductive time!"
  ["motd_uptime_fallback"]="Your system is up and running!"
  ["motd_disk_fallback"]="May your storage be plentiful!"
  ["motd_ram_fallback"]="May your memory serve you well, comrade!"
  ["motd_update_comment"]="Time for some updates!"

  # MOTD system territory
  ["motd_system_territory"]="Let me tell you about your digital territory, comrade:"
  ["motd_system_label"]="System:"
  ["motd_shell_label"]="Shell:"
  ["motd_uptime_label"]="Uptime:"
  ["motd_disk_label"]="Disk:"
  ["motd_ram_label"]="RAM:"
  ["motd_updates_label"]="Updates:"
  ["motd_unknown_value"]="Unknown"
  ["motd_unable_to_determine"]="Unable to determine"
  ["motd_packages_need_updating"]="packages need updating"

  # Component errors
  ["component_file_not_found"]="Component file not found: %s"
  ["components_directory_not_found"]="Components directory not found: %s"

  # Component cleanup - .NET Development
  ["dotnet_cleanup_running"]="🧹 Running .NET Development cleanup..."
  ["dotnet_cleaning_nuget_cache"]="  📦 Cleaning NuGet cache..."
  ["dotnet_cleaning_temp_files"]="  🗑️  Cleaning .NET temporary files..."
  ["dotnet_cleaning_nuget_packages"]="  🗑️  Cleaning NuGet packages cache..."
  ["dotnet_cleaning_omnisharp"]="  🗑️  Cleaning OmniSharp cache..."
  ["dotnet_cleaning_dotnet_temp"]="  🗑️  Cleaning dotnet temp files..."
  ["dotnet_cleanup_completed"]="✅ .NET Development cleanup completed"

  # Component cleanup - Meowvim
  ["meowvim_cleanup_running"]="🧹 Running Meowvim cleanup..."
  ["meowvim_cleaning_neovim_cache"]="  🗑️  Cleaning Neovim cache..."
  ["meowvim_cleaning_neovim_state"]="  🗑️  Cleaning Neovim state files..."
  ["meowvim_cleaning_vim_temp"]="  🗑️  Cleaning Vim temporary files..."
  ["meowvim_cleaning_swap_files"]="  🗑️  Cleaning Vim/Neovim swap files..."
  ["meowvim_cleaning_lazy_cache"]="  🗑️  Cleaning Lazy.nvim cache..."
  ["meowvim_cleaning_packer_cache"]="  🗑️  Cleaning Packer cache..."
  ["meowvim_cleanup_completed"]="✅ Meowvim cleanup completed"

  # Component cleanup - Media
  ["media_cleanup_running"]="🧹 Running Media cleanup..."
  ["media_stopping_obs"]="  ⏹️  Stopping OBS Studio..."
  ["media_removing_login_items"]="  🗑️  Removing media apps from login items..."
  ["media_cleaning_cache"]="  🗑️  Cleaning media app cache and logs..."
  ["media_cleanup_completed"]="✅ Media cleanup completed"
  ["media_user_recordings_preserved"]="ℹ️  Note: User recordings and scenes were preserved"

  # Component cleanup - Hammerspoon
  ["hammerspoon_cleanup_running"]="🧹 Running Hammerspoon cleanup..."
  ["hammerspoon_stopping"]="  ⏹️  Stopping Hammerspoon..."
  ["hammerspoon_removing_login_items"]="  🗑️  Removing Hammerspoon from login items..."
  ["hammerspoon_cleaning_logs"]="  📝 Cleaning up Hammerspoon logs..."
  ["hammerspoon_cleanup_completed"]="✅ Hammerspoon cleanup completed"

  # Component cleanup - Go Development
  ["go_dev_cleanup_running"]="🧹 Running Go Development cleanup..."
  ["go_dev_cleaning_module_cache"]="  📦 Cleaning Go module cache..."
  ["go_dev_cleaning_build_cache"]="  🗑️  Cleaning Go build cache..."
  ["go_dev_cleaning_test_cache"]="  🗑️  Cleaning Go test cache..."
  ["go_dev_removing_workspace"]="  🗑️  Removing Go workspace file..."
  ["go_dev_cleaning_gopath_pkg"]="  🗑️  Cleaning GOPATH pkg directory..."
  ["go_dev_cleanup_completed"]="✅ Go Development cleanup completed"

  # Component cleanup - JavaScript Development
  ["js_dev_cleanup_running"]="🧹 Running JavaScript Development cleanup..."
  ["js_dev_cleaning_npm_cache"]="  📦 Cleaning npm cache..."
  ["js_dev_removing_ts_cache"]="  🗑️  Removing TypeScript cache..."
  ["js_dev_cleaning_global_npm"]="  🗑️  Cleaning up global npm packages cache..."
  ["js_dev_removing_eslint_cache"]="  🗑️  Removing ESLint cache..."
  ["js_dev_cleanup_completed"]="✅ JavaScript Development cleanup completed"

  # Component cleanup - Docker Desktop
  ["docker_cleanup_running"]="🧹 Running Docker Desktop cleanup..."
  ["docker_stopping_desktop"]="  ⏹️  Stopping Docker Desktop..."
  ["docker_stopping_daemon"]="  🐳 Stopping Docker daemon..."
  ["docker_cleaning_networks_volumes"]="  🗑️  Cleaning up Docker networks and volumes..."
  ["docker_removing_login_items"]="  🗑️  Removing Docker Desktop from login items..."
  ["docker_cleanup_completed"]="✅ Docker Desktop cleanup completed"
  ["docker_images_containers_cleaned"]="ℹ️  Note: Docker images and containers have been cleaned up"
  ["docker_manual_removal_note"]="ℹ️  Note: To fully remove Docker data, manually delete ~/Library/Containers/com.docker.docker"

  # Component cleanup - Node
  ["node_cleanup_running"]="🧹 Running Node cleanup..."
  ["node_cleaning_npm_cache"]="  📦 Cleaning npm cache..."
  ["node_cleaning_yarn_cache"]="  📦 Cleaning yarn cache..."
  ["node_cleaning_pnpm_cache"]="  📦 Cleaning pnpm cache..."
  ["node_cleaning_global_npm_cache"]="  🗑️  Cleaning npm global cache..."
  ["node_cleaning_node_gyp_cache"]="  🗑️  Cleaning node-gyp cache..."
  ["node_cleanup_completed"]="✅ Node cleanup completed"

  # Component cleanup - Corporate Communication
  ["corporate_cleanup_running"]="🧹 Running Corporate Communication cleanup..."
  ["corporate_stopping_slack"]="  ⏹️  Stopping Slack..."
  ["corporate_stopping_zoom"]="  ⏹️  Stopping Zoom..."
  ["corporate_removing_login_items"]="  🗑️  Removing corporate apps from login items..."
  ["corporate_cleaning_cache"]="  🗑️  Cleaning corporate app cache and logs..."
  ["corporate_cleanup_completed"]="✅ Corporate Communication cleanup completed"

  # Component cleanup - Pipx
  ["pipx_cleanup_running"]="🧹 Running Pipx cleanup..."
  ["pipx_cleaning_cache"]="  📦 Cleaning pipx cache..."
  ["pipx_cleaning_installation_dir"]="  🗑️  Cleaning pipx installation directory..."
  ["pipx_cleaning_cache_dir"]="  🗑️  Cleaning pipx cache directory..."
  ["pipx_cleaning_binaries"]="  🗑️  Cleaning pipx binaries..."
  ["pipx_cleanup_completed"]="✅ Pipx cleanup completed"

  # Rust system setup
  ["rust_setting_up_toolchain"]="Setting up Rust toolchain"
  ["rust_toolchain_already_initialized"]="Rust toolchain already initialized"
  ["rust_installing_toolchain"]="Installing Rust toolchain with rustup"
  ["rust_toolchain_installed"]="Rust toolchain installed successfully"
  ["rust_toolchain_install_failed"]="Failed to install Rust toolchain"
  ["rust_toolchain_setup_complete"]="Rust toolchain setup complete"
  ["rust_toolchain_not_available"]="Rust toolchain installed but commands not available in current session"
  ["rust_restart_shell_notice"]="Please restart your shell or source ~/.cargo/env"
  ["rust_installing_components"]="Installing Rust components"
  ["rust_installing_clippy"]="Installing clippy component"
  ["rust_clippy_installed"]="clippy installed"
  ["rust_clippy_install_failed"]="Failed to install clippy component"
  ["rust_installing_analyzer"]="Installing rust-analyzer component"
  ["rust_analyzer_installed"]="rust-analyzer installed"
  ["rust_analyzer_install_failed"]="Failed to install rust-analyzer component"
  ["rust_rustfmt_available"]="rustfmt available"
  ["rust_rustfmt_not_available"]="rustfmt not available"

  # macOS keyboard configuration
  ["macos_keyboard_only_works_macos"]="This function only works on macOS"
  ["macos_keyboard_unknown_layout_type"]="Unknown layout type: %s. Use 'das' or 'mbp'"
  ["macos_keyboard_configuring_layouts"]="Configuring keyboard layouts for %s..."
  ["macos_keyboard_restoring_russian"]="Restoring active Russian layout"
  ["macos_keyboard_layouts_configured"]="Keyboard layouts configured for %s"

  # Mac App Store package manager
  ["mas_manual_uninstall_warning"]="Mac App Store apps cannot be automatically uninstalled via mas CLI"
  ["mas_manual_uninstall_instruction"]="Please manually uninstall the following apps through Launchpad or Applications folder:"
  ["mas_cleanup_would_skip"]="Mac App Store cleanup would be skipped (no cleanup needed)"
  ["mas_app_store_manages_downloads"]="App Store manages downloads automatically"
  ["mas_cleaning_noop"]="Cleaning Mac App Store (no-op)"
  ["mas_cleanup_skipped"]="Mac App Store cleanup skipped"

  # VS Code package manager
  ["vscode_cli_not_found_update_skip"]="VS Code CLI not found, skipping VS Code extension update"
  ["vscode_cli_not_found_uninstall_skip"]="VS Code CLI not found, skipping VS Code extension uninstall"
  ["vscode_cleanup_would_skip"]="VS Code cleanup would be skipped (no cleanup needed)"
  ["vscode_extensions_managed_automatically"]="Extensions are managed by VS Code automatically"

  # macOS system configuration
  ["macos_not_running_finder"]="Not running on macOS. Skipping Finder configuration."
  ["macos_not_running_dock"]="Not running on macOS. Skipping Dock configuration."
  ["macos_not_running_app"]="Not running on macOS. Skipping app configuration."
  ["macos_not_running_all"]="Not running on macOS. Skipping all macOS configuration."
  ["macos_config_intro"]="This script will configure various macOS settings to enhance your experience."
  ["macos_config_confirmation"]="Do you want to apply these macOS configurations?"
  ["macos_config_cancelled"]="macOS configuration cancelled."
  ["macos_config_summary"]="Summary:"
  ["macos_config_restart_notice"]="Some changes may require a logout or restart to take effect."
  ["macos_configuring_energy"]="Configuring energy saving settings..."
  ["macos_configuring_spotlight"]="Configuring Spotlight settings..."
  ["macos_configuring_console"]="Configuring Console settings..."
  ["macos_configuring_screen_capture"]="Configuring screen capture settings..."
  ["macos_configuring_mail"]="Configuring Mail application settings"

  # Component operations - additional
  ["no_components_currently_installed"]="No components are currently installed"
  ["no_components_to_uninstall"]="No components to uninstall"

  # System messages
  ["bash_3_2_compatibility_mode"]="INFO: Running in bash 3.2 compatibility mode"
  ["bash_upgrade_recommendation"]="      Consider upgrading to bash 4.0+ for optimal performance"
  ["bash_version_info"]="Bash version: %s (%s)"

  # Symlinks operations
  ["symlinks_listing_all_backups"]="Listing all symlink backups:"
  ["symlinks_no_backups_found"]="  No symlink backups found"
  ["symlinks_listing_backups_pattern"]="Listing backups for pattern: %s"
  ["symlinks_backup_not_found"]="Backup file not found: %s"
  ["symlinks_restoring_backup"]="Restoring backup: %s -> %s"
  ["symlinks_no_backups_for_pattern"]="  No backups found for pattern: %s"
  ["symlinks_target_exists_backup"]="  Target location already exists, creating backup of current state"
  ["symlinks_current_backed_up"]="  Current state backed up to %s"
  ["symlinks_backup_current_failed"]="  Failed to backup current state"
  ["symlinks_restore_success"]="  Successfully restored %s"
  ["symlinks_restore_failed"]="  Failed to restore backup"
  ["symlinks_backup_entry_simple"]="  %s -> %s (created: %s)"

  # Session and initialization
  ["session_unsupported_package_manager"]="No supported package manager found for this OS. Skipping system setup."
  ["session_yq_install_failed"]="Failed to ensure yq installation"

  # Bash version and compatibility
  ["bash_modern_features_available"]="Modern bash features available"
  ["bash_using_compatibility_mode"]="Using compatibility mode for bash 3.2"
  ["bash_3_2_compatibility_mode"]="Running in bash 3.2 compatibility mode"
  ["bash_upgrade_recommendation"]="Consider upgrading to bash 4.0+ for optimal performance"

  # Component package management
  ["package_updates_errors_occurred"]="Package updates: ✗ %d errors occurred"

  # Component symlinks management
  ["symlinks_removing_for_component"]="Removing symlinks for component: %s"
  ["symlinks_remove_failed_for"]="Failed to remove symlinks for '%s'"
  ["symlinks_removed_successfully"]="Component symlinks removed successfully (%d symlink files)"
  ["symlinks_removed_with_errors"]="Component symlinks removed with %d errors (%d/%d symlink files)"
  ["symlinks_for_removed_successfully"]="Symlinks for '%s' removed successfully"
  ["dry_run_would_remove_symlink"]="Would remove symlink: %s"
  ["dry_run_would_skip_non_symlink"]="Would skip non-symlink: %s"
  ["dry_run_would_skip_non_existent"]="Would skip non-existent: %s"
  ["symlinks_yq_required"]="yq is required to parse symlink configuration. Please install yq."
  ["symlinks_file_not_found"]="No symlinks file found for '%s' at %s"
  ["symlinks_none_defined"]="No symlinks defined in %s"
  ["symlinks_missing_target_key"]="Missing 'target' key in symlink entry %d of %s"
  ["symlinks_failed_restore_backup"]="Failed to restore backup for %s"
  ["symlinks_failed_remove"]="Failed to remove symlink: %s"
  ["symlinks_processed_with_backup"]="Processed %d symlinks (%d restored from backup)"
  ["symlinks_processed_no_backup"]="Processed %d symlinks (no backups to restore)"
  ["symlinks_failed_to_process"]="Failed to process %d of %d symlinks"

  # Component operations
  ["component_already_installing"]="Component '%s' already being installed in this session, skipping"
  ["component_already_updated"]="Component '%s' already updated in this session, skipping"
  ["component_not_installed_skip_update"]="Component '%s' is not installed, skipping update"
  ["components_update_summary"]="Will update %d component%s with dependencies"
  ["components_update_total"]="Total components to update: %d"
  ["components_update_requested"]="Requested components: %s"
  ["components_update_dependencies"]="Dependencies: %s"
  ["component_update_failed_continue"]="Failed to update component: %s, continuing with other components"
  ["component_repo_update_failed"]="Repository update failed, continuing with package updates"
  ["component_packages_update_failed"]="Some package updates may have failed"
  ["component_installing_prefix"]="Installing component: %s"
  ["component_updating_prefix"]="Updating component: %s"
  ["component_removing_unused"]="Removing unused dependency: %s"
  ["component_not_installed_warning"]="Component '%s' is not installed"
  ["component_file_not_found_error"]="Component file not found: %s"
  ["component_uninstall_blocked_components"]="Cannot uninstall component '%s' because it is required by the following components:"
  ["component_uninstall_blocked_presets"]="Cannot uninstall component '%s' because it is required by the following installed presets:"
  ["component_uninstall_dependent_item"]="  - %s"
  ["component_uninstall_use_force"]="Please uninstall the dependent components first, or use --force to override."
  ["component_uninstall_presets_use_force"]="Please uninstall the presets first, use a different preset configuration, or use --force to override."
  ["component_force_flag_detected"]="Force flag detected - skipping dependency checks"
  ["component_uninstall_failed"]="Failed to uninstall component: %s"
  ["components_uninstalled_with_errors"]="Component%s uninstalled with some warnings/errors"
  ["component_symlinks_removed_successfully"]="Symlinks removed and backups restored successfully"
  ["component_symlinks_removal_failed"]="Some symlink removal/backup restoration may have failed"
  ["component_packages_uninstall_failed"]="Some package uninstallation may have failed"
  ["component_tracking_removed"]="Component tracking removed"

  # Component operation step headers
  ["component_uninstall_order"]="Uninstall order:"
  ["component_removing_symlinks"]="Removing symlinks and restoring backups"
  ["component_uninstalling_packages"]="Uninstalling packages"
  ["component_removing_tracking"]="Removing component tracking"
  ["component_updating_repository"]="Updating repository for %s"
  ["component_updating_packages"]="Updating packages for %s"

  # Component uninstall operations
  ["components_uninstall_summary"]="Will uninstall %d component%s with dependencies"
  ["components_uninstall_total"]="Total components to uninstall: %d"
  ["components_uninstall_requested"]="Requested components: %s"
  ["components_uninstall_unused"]="Unused dependencies: %s"

  # Component status indicators
  ["component_already_installed_status"]=" (already installed)"
  ["component_requested_indicator"]="  ➤ %s (requested component)%s"
  ["component_dependency_indicator"]="  ↪ %s (dependency)%s"
  ["component_requested_uninstall_indicator"]="  ➤ %s (requested component)"
  ["component_unused_dependency_indicator"]="  ↪ %s (unused dependency)"

  # Component dependency warnings
  ["circular_dependencies_detected"]="Circular dependencies detected among: %s"

  # Package managers
  ["homebrew_install"]="Installing Homebrew|Homebrew installed successfully|Homebrew installation failed"
  ["homebrew_cleanup"]="Cleaning Homebrew|Homebrew cleanup completed|Homebrew cleanup failed"
  ["homebrew_prune"]="Pruning cache and unused packages|Homebrew cleanup completed|Homebrew cleanup failed"

  ["npm_cache_clean"]="Cleaning npm cache|npm cache cleaned|npm cache cleanup failed"
  ["npm_clean"]="Cleaning npm|npm cache cleaned|npm cleanup failed"

  ["apt_update"]="Updating APT index|APT index updated|Failed to update APT index"
  ["apt_cleanup"]="Cleaning APT|APT cleanup completed|APT cleanup failed"
  ["apt_remove_unused"]="Removing unused packages|Unused packages removed|Failed to remove unused packages"
  ["apt_clean_cache"]="Cleaning cache|Cache cleaned|Failed to clean cache"

  ["apk_update"]="Updating apk index|apk index updated|Failed to update apk index"
  ["apk_cleanup"]="Cleaning apk|apk cleanup completed|apk cleanup failed"

  ["pacman_sync"]="Syncing package database|Package database synced|Failed to sync package database"
  ["pacman_cleanup"]="Cleaning pacman|pacman cleanup completed|pacman cleanup failed"
  ["pacman_prune"]="Pruning cache|Cache pruned|Failed to prune cache"

  # Repository operations
  ["clone_repository"]="Cloning %s repository|Repository cloned successfully|Failed to clone repository"
  ["update_repository"]="Updating %s repository|Repository updated successfully|Failed to update repository"

  # System setup
  ["oh_my_zsh_install"]="Installing Oh My Zsh|Oh My Zsh installation completed|Failed to install Oh My Zsh"
  ["oh_my_zsh_update"]="Updating Oh My Zsh|Oh My Zsh update completed|Failed to update Oh My Zsh"

  ["tmux_tpm_install"]="Installing tmux Plugin Manager|tmux Plugin Manager installation completed|Failed to install tmux Plugin Manager"
  ["tmux_tpm_update"]="Updating tmux Plugin Manager|tmux Plugin Manager update completed|Failed to update tmux Plugin Manager"

  ["rust_install"]="Installing Rust toolchain with rustup|Rust toolchain installed successfully|Failed to install Rust toolchain"
  ["rust_clippy"]="Installing clippy component|clippy installed|Failed to install clippy component"
  ["rust_analyzer"]="Installing rust-analyzer component|rust-analyzer installed|Failed to install rust-analyzer component"

  # Package manager initialization
  ["init_apk"]="Initializing apk package manager|apk package manager ready|apk initialization failed"
  ["init_apt"]="Initializing APT package manager|APT package manager ready|APT initialization failed"
  ["init_pacman"]="Initializing pacman package manager|pacman package manager ready|pacman initialization failed"
  ["init_homebrew"]="Initializing Homebrew package manager|Homebrew package manager ready|Homebrew initialization failed"

  # Tools installation
  ["install_yq"]="Installing yq v%s|yq v%s installed to /usr/local/bin/yq|Failed to download yq from %s"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a static message by key
get_static_message() {
  local key="$1"
  echo "${UI_MESSAGES[$key]:-$key}"
}

# Format a template message with parameters
format_template_message() {
  local template_key="$1"
  shift
  local template="${UI_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}

# Get spinner message parts (returns: progress|success|fail)
get_spinner_messages() {
  local key="$1"
  echo "${UI_MESSAGES[$key]:-$key||}"
}

# Parse spinner messages into individual parts
parse_spinner_messages() {
  local key="$1"
  local messages
  messages=$(get_spinner_messages "$key")
  IFS='|' read -r progress_msg success_msg fail_msg <<<"$messages"

  # Always output the progress message for command substitution
  echo "$progress_msg"

  # Export for caller to use
  export SPINNER_PROGRESS="$progress_msg"
  export SPINNER_SUCCESS="$success_msg"
  export SPINNER_FAIL="$fail_msg"
}
