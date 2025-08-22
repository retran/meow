#!/usr/bin/env bash

# lib/core/strings_core.sh - Core system UI strings

if [[ -n "${_LIB_CORE_STRINGS_CORE_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_STRINGS_CORE_SOURCED=1

# ============================================================================
# STATIC MESSAGES - Core system operations
# ============================================================================

declare -A UI_CORE_STATIC_MESSAGES=(
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
  ["command_more_lines_hidden"]="... and %d more lines. Use MEOW_VERBOSE=true for full output"
)

# ============================================================================
# TEMPLATE MESSAGES - Core system operations with parameters
# ============================================================================

declare -A UI_CORE_TEMPLATE_MESSAGES=(
  # General operations with counts
  ["components_install_count"]="Will install %d component%s with dependencies"
  ["components_update_count"]="Will update %d component%s with dependencies"
  ["total_components_install"]="Total components to install: %d"
  ["total_components_update"]="Total components to update: %d"
  ["found_components"]="Found %d installed components: %s"

  # Lists and items
  ["requested_components"]="Requested components: %s"
  ["new_dependencies"]="New dependencies: %s"
  ["preset_components"]="Preset components: %s"
  ["dependencies_list"]="Dependencies: %s"

  # Errors
  ["no_components_specified_install"]="No components specified for installation"
  ["no_components_specified_update"]="No components specified for update"
  ["no_components_specified_uninstall"]="No components specified for uninstall"
)

# ============================================================================
# SPINNER MESSAGES - Core system operations
# ============================================================================

declare -A UI_CORE_SPINNER_MESSAGES=(
  # System setup
  ["oh_my_zsh_install"]="Installing Oh My Zsh|Oh My Zsh installation completed|Failed to install Oh My Zsh"
  ["oh_my_zsh_update"]="Updating Oh My Zsh|Oh My Zsh update completed|Failed to update Oh My Zsh"

  ["tmux_tpm_install"]="Installing tmux Plugin Manager|tmux Plugin Manager installation completed|Failed to install tmux Plugin Manager"
  ["tmux_tpm_update"]="Updating tmux Plugin Manager|tmux Plugin Manager update completed|Failed to update tmux Plugin Manager"

  ["rust_install"]="Installing Rust toolchain with rustup|Rust toolchain installed successfully|Failed to install Rust toolchain"
  ["rust_clippy"]="Installing clippy component|clippy installed|Failed to install clippy component"
  ["rust_analyzer"]="Installing rust-analyzer component|rust-analyzer installed|Failed to install rust-analyzer component"

  # Tools installation
  ["install_yq"]="Installing yq v%s|yq v%s installed to /usr/local/bin/yq|Failed to download yq from %s"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a core static message by key
get_core_static_message() {
  local key="$1"
  echo "${UI_CORE_STATIC_MESSAGES[$key]:-$key}"
}

# Format a core template message with parameters
format_core_template_message() {
  local template_key="$1"
  shift
  local template="${UI_CORE_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}

# Get core spinner message parts
get_core_spinner_messages() {
  local key="$1"
  echo "${UI_CORE_SPINNER_MESSAGES[$key]:-$key||}"
}

# Parse core spinner messages into individual parts
parse_core_spinner_messages() {
  local key="$1"
  local messages
  messages=$(get_core_spinner_messages "$key")
  IFS='|' read -r progress_msg success_msg fail_msg <<<"$messages"

  # Export for caller to use
  export SPINNER_PROGRESS="$progress_msg"
  export SPINNER_SUCCESS="$success_msg"
  export SPINNER_FAIL="$fail_msg"
}
