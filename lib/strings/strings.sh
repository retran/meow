#!/usr/bin/env bash

# lib/strings/strings.sh - Unified strings file with modular structure

if [[ -n "${_LIB_STRINGS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_SOURCED=1

# ============================================================================
# CORE STATIC MESSAGES
# ============================================================================

declare -A UI_STATIC_MESSAGES=(
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
  ["component_tracking_removed"]="Component tracking removed"
  ["requested_components"]="Requested components: %s"
  ["new_dependencies"]="New dependencies: %s"

  # Repository operations
  ["repo_updated"]="Repository updated successfully"
  ["repo_cleaned"]="Repository cleaned up"

  # Package operations
  ["packages_updated"]="Packages updated successfully"
  ["packages_uninstalled"]="Packages uninstalled successfully"
  ["package_updates_failed"]="Some package updates may have failed"
  ["package_uninstall_failed"]="Some package uninstallation may have failed"

  # Symlinks operations
  ["symlinks_restored"]="Symlinks removed and backups restored successfully"

  # Package managers
  ["npm_not_found"]="npm not found"
  ["npm_not_found_would_fail"]="npm not found - would fail setup"
  ["npm_already_available"]="npm already available, no setup needed"
  ["go_not_found"]="Go not found"
  ["go_not_found_would_fail"]="Go not found - would fail setup"
  ["go_already_available"]="Go already available, ready for package installation"
  ["go_available"]="Go available"
  ["go_setting_up"]="Setting up Go"
  ["go_packages_cannot_uninstall"]="Go packages cannot be automatically uninstalled via go command"
  ["go_packages_manual_removal"]="Go packages are installed to GOPATH/bin. Please manually remove binaries if needed:"
  ["go_cleanup_would_skip"]="Go cleanup would be skipped (no cleanup needed)"
  ["go_cleaning_noop"]="Cleaning Go (no-op)"
  ["go_cleanup_skipped"]="Go cleanup skipped"
  ["cargo_not_found"]="cargo not found"
  ["cargo_not_found_would_fail"]="cargo not found - would fail setup"
  ["cargo_already_available"]="Cargo already available, ready for package installation"
  ["cargo_available"]="Cargo available"
  ["cargo_setting_up"]="Setting up Cargo"
  ["apt_get_not_found"]="apt-get not found - would fail setup"
  ["apt_would_update_index"]="Would update APT package index"
  ["apt_update_command"]="Command: sudo apt-get update"
  ["apt_would_refresh_info"]="Would refresh available package information"
  ["apt_updating_index"]="Updating APT index"
  ["apt_index_updated"]="APT index updated"
  ["apt_index_update_failed"]="Failed to update APT index"
  ["vscode_setting_up"]="Setting up VS Code CLI"
  ["vscode_cli_not_found_would_warn"]="VS Code CLI not found - would warn and skip extensions"
  ["vscode_cli_already_available"]="VS Code CLI already available, ready for extension installation"
  ["vscode_cli_not_found_skip"]="VS Code CLI not found, skipping extensions"
  ["vscode_cli_available"]="VS Code CLI available"
  ["vscode_cli_not_found_extension_skip"]="VS Code CLI not found, skipping VS Code extension installation"
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
)

# ============================================================================
# TEMPLATE MESSAGES - Strings with parameters using printf format
# ============================================================================

declare -A UI_TEMPLATE_MESSAGES=(
  # General operations with counts
  ["components_install_count"]="Will install %d component%s with dependencies"
  ["components_update_count"]="Will update %d component%s with dependencies"
  ["total_components_install"]="Total components to install: %d"
  ["total_components_update"]="Total components to update: %d"
  ["found_components"]="Found %d installed components: %s"
  ["command_more_lines_hidden"]="... and %d more lines. Use MEOW_VERBOSE=true for full output"

  # Component operations
  ["setting_up_component"]="Setting up component: %s"
  ["cleaning_component"]="Cleaning up component: %s"
  ["installing_component"]="Installing component: %s"
  ["updating_component"]="Updating component: %s"
  ["uninstalling_component"]="Uninstalling component: %s"
  ["component_installed"]="Component installed successfully: %s"
  ["component_updated"]="Component updated successfully: %s"
  ["component_uninstalled"]="Component uninstalled successfully: %s"
  ["component_not_found"]="Component '%s' not found"
  ["component_not_available"]="Component '%s' is not available on this platform or dependencies are missing"
  ["component_already_installed"]="Component '%s' is already installed"
  ["component_marked_manual"]="Component '%s' marked as manually installed"
  ["component_install_failed"]="Failed to install component: %s"
  ["component_packages_failed"]="Failed to install packages for component '%s'"
  ["component_repo_failed"]="Failed to clone repository for component '%s'"

  # Repository operations
  ["removing_repo"]="Removing existing repository for component: %s"
  ["cloning_repo"]="Cloning repository to .downloads/%s"
  ["updating_repo"]="Updating repository for component: %s"
  ["cleaning_repo"]="Cleaning up repository for %s"
  ["cloning_component_repo"]="Cloning %s repository"
  ["updating_component_repo"]="Updating %s repository"
  ["repo_component_install"]="Installing repository-based component: %s"
  ["repo_cleaned_for"]="Repository cleaned up for %s"
  ["repo_update_msg"]="Updating repository for component: %s"
  ["repo_cloned_success"]="Repository cloned successfully for %s"
  ["repo_clone_failed"]="Failed to clone repository for %s"
  ["repo_updated_success"]="Repository updated successfully for %s"
  ["repo_update_failed"]="Failed to update repository for %s"

  # Package operations
  ["installing_packages"]="Installing packages for %s"
  ["updating_packages"]="Updating packages for %s"
  ["removing_packages"]="Uninstalling packages"
  ["packages_manager_display"]="(%s) %s"
  ["package_manager_removal"]="%s Package Removal (%s)"

  # Symlinks operations
  ["setting_up_symlinks"]="Setting up symlinks for component: %s"
  ["removing_symlinks"]="Removing symlinks for component: %s"
  ["symlinks_configured"]="Symlinks for '%s' configured successfully"
  ["symlinks_removed"]="Symlinks for '%s' removed successfully"
  ["symlinks_completed"]="Symlinks for '%s' completed (%ss)"
  ["symlinks_configuration_checked"]="Symlinks: ✓ %d configuration%s checked, no changes needed"
  ["symlinks_errors_successful"]="Symlinks: ✗ %d error%s, %d successful"
  ["symlinks_configured_successfully"]="Component symlinks configured successfully (%d symlink files)"
  ["symlinks_configured_with_errors"]="Component symlinks configured with %d errors (%d/%d symlink files)"
  ["symlinks_for_configured"]="Symlinks for '%s' configured successfully"
  ["symlinks_setup_failed"]="Failed to setup symlinks for '%s'"
  ["symlinks_listing_backups_pattern"]="Listing backups for pattern: %s"
  ["symlinks_backup_not_found"]="Backup file not found: %s"
  ["symlinks_restoring_backup"]="Restoring backup: %s -> %s"
  ["symlinks_backup_entry"]="  %s -> %s (created: %s)"
  ["symlinks_no_backups_for_pattern"]="  No backups found for pattern: %s"
  ["symlinks_current_backed_up"]="  Current state backed up to %s"
  ["symlinks_restore_success"]="  Successfully restored %s"

  # Package managers
  ["setting_up_manager"]="Setting up %s"
  ["manager_ready"]="%s ready"
  ["cleaning_manager"]="Cleaning %s"
  ["manager_cleanup_completed"]="%s cleanup completed"
  ["setting_up_package_manager"]="Setting up %s..."
  ["cleaning_package_manager"]="Cleaning %s..."

  # Lists and items
  ["requested_components"]="Requested components: %s"
  ["new_dependencies"]="New dependencies: %s"
  ["preset_components"]="Preset components: %s"
  ["dependencies_list"]="Dependencies: %s"

  # Presets
  ["installing_preset"]="==> Installing Preset: %s"
  ["preset_not_found"]="Preset '%s' not found"
  ["preset_not_available"]="Preset '%s' is not available on this platform"
  ["preset_already_installed"]="Preset '%s' is already installed"
  ["preset_not_installed"]="Preset '%s' is not installed"
  ["preset_updated"]="Preset '%s' updated successfully"
  ["preset_failed_components"]="Failed to install required components"
  ["preset_no_components"]="No components to install for this preset"
  ["preset_components_count"]="Will install %d preset components with dependencies"
  ["preset_components_update_msg"]="Updating preset components"

  # Errors
  ["no_components_specified_install"]="No components specified for installation"
  ["no_components_specified_update"]="No components specified for update"
  ["no_components_specified_uninstall"]="No components specified for uninstall"

  # Dry-run operations
  ["dry_run_would_execute"]="Would execute: %s"
  ["dry_run_command"]="Command: %s"
  ["dry_run_create_symlink"]="Would create symlink: %s -> %s"
  ["dry_run_create_directory"]="Would create directory: %s"
  ["dry_run_remove_file"]="Would remove file: %s"
  ["dry_run_remove_directory"]="Would remove directory: %s"
  ["dry_run_backup_file"]="Would backup file: %s"
  ["dry_run_restore_file"]="Would restore file: %s from %s"
  ["dry_run_file_operation"]="Would perform file operation '%s' on: %s"

  # Component dry-run operations
  ["dry_run_create_component_symlink"]="Would create component installation symlink: %s -> %s"
  ["dry_run_mark_manual_install"]="Would mark as manually installed: %s -> %s"
  ["dry_run_remove_component_symlink"]="Would remove component installation symlink: %s"
  ["dry_run_remove_manual_symlink"]="Would remove manual installation symlink: %s"

  # MOTD templates
  ["motd_greeting"]="%s, сomrade %s!"
  ["motd_greeting_comrade"]="%s, сomrade %s!"
  ["motd_calendar"]="Calendar shows %s."
  ["motd_calendar_shows"]="Calendar shows %s"
  ["motd_clock"]="Clock purrs at %s."
  ["motd_clock_purrs"]="Clock purrs at %s"
  ["motd_ascii_art_not_found"]="ASCII art file not found: %s"
  ["motd_system_territory"]="Let me tell you about your digital territory, comrade:"
  ["motd_system_info"]="System:     %s"
  ["motd_shell_info"]="Shell:      %s"

  # Rust system setup
  ["rust_version_info"]="Rust version: %s"

  # macOS keyboard configuration
  ["macos_keyboard_unknown_layout_type"]="Unknown layout type: %s. Use 'das' or 'mbp'"
  ["macos_keyboard_configuring_layouts"]="Configuring keyboard layouts for %s..."
  ["macos_keyboard_layouts_configured"]="Keyboard layouts configured for %s"

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
  ["motd_uptime_info"]="Uptime:     %s"
  ["motd_disk_info"]="Disk:       %s"
  ["motd_ram_info"]="RAM:        %s"
  ["motd_updates_info"]="Updates:    %s packages need updating"
  ["motd_computer_name_set"]="Computer name set to %s"

  # macOS configuration
  ["macos_setting_computer_name"]="Computer name set to %s"
  ["macos_system_defaults"]="System Defaults"
  ["macos_finder_config"]="Finder Configuration"
  ["macos_dock_config"]="Dock Configuration"
  ["macos_app_config"]="App Configuration"
  ["macos_configuration"]="macOS Configuration"

  # Package manager summaries
  ["package_summary_installed"]="%s: ✓ %d installed, %d already present"
  ["package_summary_present"]="%s: ✓ %d/%d already present"
  ["package_summary_failed"]="%s: ✗ %d failed, %d installed, %d already present"
  ["package_summary_updated"]="%s: ✓ %d updated, %d up-to-date"
  ["package_summary_update_failed"]="%s: ✗ %d failed, %d updated, %d up-to-date"
  ["package_summary_uninstalled"]="%s: ✓ %d uninstalled, %d not installed"
  ["package_summary_uninstall_failed"]="%s: ✗ %d failed, %d uninstalled, %d not installed"
)

# ============================================================================
# SPINNER MESSAGES - Progress|Success|Fail triplets for ui_spinner
# ============================================================================

declare -A UI_SPINNER_MESSAGES=(
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
  echo "${UI_STATIC_MESSAGES[$key]:-$key}"
}

# Format a template message with parameters
format_template_message() {
  local template_key="$1"
  shift
  local template="${UI_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}

# Get spinner message parts (returns: progress|success|fail)
get_spinner_messages() {
  local key="$1"
  echo "${UI_SPINNER_MESSAGES[$key]:-$key||}"
}

# Parse spinner messages into individual parts
parse_spinner_messages() {
  local key="$1"
  local messages
  messages=$(get_spinner_messages "$key")
  IFS='|' read -r progress_msg success_msg fail_msg <<<"$messages"

  # Export for caller to use
  export SPINNER_PROGRESS="$progress_msg"
  export SPINNER_SUCCESS="$success_msg"
  export SPINNER_FAIL="$fail_msg"
}
