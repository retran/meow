#!/usr/bin/env bash

# test_ui.sh - Test script for new semantic UI system

# Set up environment
export MEOW="/Users/retran/.meow"
export MEOW_VERBOSE="true"

# Source the new UI system
source "${MEOW}/lib/core/ui.sh"

echo "================================================"
echo "        TESTING NEW SEMANTIC UI SYSTEM        "
echo "================================================"
echo

# Test basic message functions
ui_title "Basic Message Functions"
ui_message "This is a regular message"
ui_success "This is a success message"
ui_info "This is an info message"
ui_warning "This is a warning message"
ui_error "This is an error message"
ui_content "This is content text"
echo

# Test action functions
ui_title "Action Functions"
ui_action_start "Starting some operation"
ui_action_success "Operation completed successfully"
ui_action_warning "Operation completed with warnings"
ui_action_error "Operation failed"
echo

# Test component operations
ui_title "Component Operations"
ui_component_installing "neovim"
ui_component_installed "neovim"
ui_component_updating "docker"
ui_component_updated "docker"
ui_component_setup "homebrew"
ui_component_cleanup "old-packages"
echo

# Test package manager operations
ui_title "Package Manager Operations"
ui_package_manager_setup "homebrew"
ui_package_manager_ready "homebrew"
ui_packages_installing_header "development-tools"
ui_package_already_installed "git"
ui_package_up_to_date "curl"
echo

# Test repository operations
ui_title "Repository Operations"
ui_repo_cloning "awesome-dotfiles"
ui_repo_updating "my-configs"
ui_repo_updated
ui_repo_cleaning "temp-repos"
ui_repo_cleaned "temp-repos"
echo

# Test symlink operations
ui_title "Symlink Operations"
ui_symlinks_setting_up "configuration"
ui_symlinks_configured "configuration"
ui_symlinks_removing "old-config"
ui_symlinks_removed "old-config"
echo

# Test headers and structure
ui_title "Headers and Structure"
ui_header "Main Section"
ui_subheader "Subsection"
ui_step_header "Processing Files" "3" "5"
ui_list_item "File 1: config.yaml"
ui_list_item "File 2: settings.json"
ui_indent "Nested configuration item"
echo

# Test template messages
ui_title "Template Messages"
ui_info "$(format_template_message 'component_installed' 'my-component')"
ui_info "$(format_template_message 'installing_packages' 'development-tools')"
echo

# Test spinner messages (just show the messages, not actual spinners)
ui_title "Spinner Message Examples"
parse_spinner_messages "init_homebrew"
ui_info "Progress: $SPINNER_PROGRESS"
ui_success "Success: $SPINNER_SUCCESS"
ui_error "Failure: $SPINNER_FAIL"
echo

# Test confirmation
ui_title "Interactive Functions"
echo "Note: Confirmation prompt would appear here in interactive mode"
echo "ui_confirm 'Do you want to continue?' 'Y'"
echo

# Test final summary
ui_title "Final Summary"
show_final_summary "Installation" "my-component" "true" "$(date +%s)"
echo

echo "================================================"
echo "           UI SYSTEM TEST COMPLETED           "
echo "================================================"
