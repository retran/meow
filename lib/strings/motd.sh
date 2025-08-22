#!/usr/bin/env bash

# lib/strings/motd.sh - MOTD (Message of the Day) UI strings

if [[ -n "${_LIB_STRINGS_MOTD_SOURCED:-}" ]]; then
  return 0
fi
_LIB_STRINGS_MOTD_SOURCED=1

# ============================================================================
# STATIC MESSAGES - MOTD fallbacks
# ============================================================================

declare -A UI_MOTD_STATIC_MESSAGES=(
  # MOTD fallbacks
  ["motd_fallback"]="A fancy digital cat comment should be here"
  ["motd_greeting_default"]="Meowvelous day"
  ["motd_time_fallback"]="Hope you have a purr-ductive time!"
  ["motd_uptime_fallback"]="Your system is up and running!"
  ["motd_disk_fallback"]="May your storage be plentiful!"
  ["motd_ram_fallback"]="May your memory serve you well, comrade!"
  ["motd_update_comment"]="Time for some updates!"
)

# ============================================================================
# TEMPLATE MESSAGES - MOTD templates with parameters
# ============================================================================

declare -A UI_MOTD_TEMPLATE_MESSAGES=(
  # MOTD templates
  ["motd_greeting"]="%s, сomrade %s!"
  ["motd_calendar"]="Calendar shows %s."
  ["motd_clock"]="Clock purrs at %s."
  ["motd_system_territory"]="Let me tell you about your digital territory, comrade:"
  ["motd_system_info"]="System:     %s"
  ["motd_shell_info"]="Shell:      %s"
  ["motd_uptime_info"]="Uptime:     %s"
  ["motd_disk_info"]="Disk:       %s"
  ["motd_ram_info"]="RAM:        %s"
  ["motd_updates_info"]="Updates:    %s packages need updating"
  ["motd_computer_name_set"]="Computer name set to %s"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get a MOTD static message by key
get_motd_static_message() {
  local key="$1"
  echo "${UI_MOTD_STATIC_MESSAGES[$key]:-$key}"
}

# Format a MOTD template message with parameters
format_motd_template_message() {
  local template_key="$1"
  shift
  local template="${UI_MOTD_TEMPLATE_MESSAGES[$template_key]:-$template_key}"
  printf "$template" "$@"
}
