#!/usr/bin/env bash

# lib/core/ui.sh - UI functions for terminal output

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_UI_SOURCED=1

source "${MEOW}/lib/core/colors.sh"

# Global verbosity control
MEOW_VERBOSE="${MEOW_VERBOSE:-false}"

# Error/warning tracking for final summary
declare -g MEOW_ERROR_COUNT=0
declare -g MEOW_WARNING_COUNT=0
declare -ga MEOW_ERRORS=()
declare -ga MEOW_WARNINGS=()

# Internal helper for colored messages
_base_msg() {
  local color_prefix="$1"
  shift
  echo -e "${color_prefix}${*}${RESET}"
}

# Internal helper for icon messages
_icon_msg_core() {
  local icon_and_color="$1"
  shift
  echo -e "${icon_and_color}${RESET}${NORMAL}${*}${RESET}"
}

# Show command output on error
_print_temp_output_if_exists() {
  local temp_file="$1"

  if [[ -s "$temp_file" ]]; then
    if [[ "$MEOW_VERBOSE" == "true" ]]; then
      echo ""
      error "Command output:"
      while IFS= read -r line; do
        content "$line"
      done <"$temp_file"
    else
      # In non-verbose mode, show only the first few lines and suggest verbose mode
      echo ""
      error "Command failed. First few lines:"
      head -n 3 "$temp_file" | while IFS= read -r line; do
        content "$line"
      done
      local line_count
      line_count=$(wc -l < "$temp_file")
      if [[ $line_count -gt 3 ]]; then
        info "... ($((line_count - 3)) more lines hidden. Run with --verbose for full output)"
      fi
    fi
  fi
}

# Message functions
msg() { _base_msg "${NORMAL}" "$@"; }
success() { _base_msg "${SUCCESS}" "$@"; }
error() {
  _base_msg "${ERROR}" "$@" >&2
  ((MEOW_ERROR_COUNT++)) || true
  MEOW_ERRORS+=("$*")
}
warning() {
  _base_msg "${WARNING}" "$@"
  ((MEOW_WARNING_COUNT++)) || true
  MEOW_WARNINGS+=("$*")
}
info() { _base_msg "${INFO}" "$@"; }
content() { _base_msg "${CONTENT}" "$@"; }

# Verbose-only messages
verbose_msg() { [[ "$MEOW_VERBOSE" == "true" ]] && msg "$@"; }
verbose_info() { [[ "$MEOW_VERBOSE" == "true" ]] && info "$@"; }
verbose_action_msg() { [[ "$MEOW_VERBOSE" == "true" ]] && action_msg "$@"; }

# Header functions
title() { _base_msg "${HEADER}${BOLD}" "$@"; }
header() { _base_msg "${HEADER}" "$@"; }
subheader() { _base_msg "${SUBHEADER}" "$@"; }

# Icon messages
action_msg() { _icon_msg_core "${INFO}➤ " "$@"; }
success_tick_msg() { _icon_msg_core "${SUCCESS}✓ " "$@"; }
info_italic_msg() { _icon_msg_core "${INFO}ℹ︎ " "$@"; }
dependency_msg() { _icon_msg_core "${NORMAL}↪ " "$@"; }
error_msg() {
  _icon_msg_core "${ERROR}✗ " "$@" >&2
  ((MEOW_ERROR_COUNT++)) || true
  MEOW_ERRORS+=("$*")
}
warning_msg() {
  _icon_msg_core "${WARNING}⚠️ " "$@"
  ((MEOW_WARNING_COUNT++)) || true
  MEOW_WARNINGS+=("$*")
}
list_item_msg() { _icon_msg_core "${NORMAL}    " "$@"; }
emphasized_msg() { _icon_msg_core "${BOLD}" "$@"; }
indent_msg() { _icon_msg_core "${NORMAL}  ↳ " "$@"; }

# Verbose-only icon messages
verbose_action_msg() { [[ "$MEOW_VERBOSE" == "true" ]] && action_msg "$@"; }
verbose_success_tick_msg() { [[ "$MEOW_VERBOSE" == "true" ]] && success_tick_msg "$@"; }

# Interactive confirmation prompt
ui_confirm() {
  local message="${1:-Confirm}"
  local default_response="${2:-N}"
  local prompt_suffix
  local default_upper

  default_upper=$(echo "$default_response" | tr '[:lower:]' '[:upper:]')

  case "$default_upper" in
    Y | YES) prompt_suffix="(Y/n)" ;;
    *) prompt_suffix="(y/N)" ;;
  esac

  local response
  while true; do
    echo -ne "${INFO}❓ ${RESET}${NORMAL}${message} ${prompt_suffix} ${RESET}"
    read -r response </dev/tty

    if [[ -z "$response" ]]; then
      response="$default_response"
    fi

    local response_upper
    response_upper=$(echo "$response" | tr '[:lower:]' '[:upper:]')

    case "$response_upper" in
      Y | YES) return 0 ;;
      N | NO) return 1 ;;
      *) warning "Please answer 'y' for yes or 'n' for no." ;;
    esac
  done
}

# Silent spinner - shows spinner during operation, then removes the line completely
ui_silent_spinner() {
  local msg="$1"
  shift

  local temp_output_file
  temp_output_file=$(mktemp)

  # Start spinner animation in background
  {
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    while true; do
      local char="${spinner_chars:$((i % ${#spinner_chars})):1}"
      echo -ne "\r${char} ${msg}"
      sleep 0.1
      ((i++))
    done
  } &
  local spinner_pid=$!

  # Run the actual command
  "$@" >"$temp_output_file" 2>&1 &
  local cmd_pid=$!

  # Wait for command to complete
  wait "$cmd_pid"
  local cmd_exit_status=$?

  # Stop spinner
  kill "$spinner_pid" 2>/dev/null
  wait "$spinner_pid" 2>/dev/null

  # Clear the line completely
  echo -ne "\r$(tput el)"

  # Clean up temp file
  if [[ $cmd_exit_status -ne 0 && -s "$temp_output_file" ]]; then
    # If command failed and there's output, we might want to show it
    # But for now, we'll keep it silent and let the caller handle errors
    :
  fi

  rm -f "$temp_output_file"
  return "$cmd_exit_status"
}

# Spinner function with progress indicator
ui_spinner() {
  local msg="$1"
  shift

  local success_msg=""
  local fail_msg=""
  local unchanged_msg=""
  local unchanged_pattern=""

  while [[ $# -gt 0 && ("$1" == "--success" || "$1" == "--fail" || "$1" == "--unchanged" || "$1" == "--pattern") ]]; do
    if [[ "$1" == "--success" ]]; then
      success_msg="$2"
      shift 2
    elif [[ "$1" == "--fail" ]]; then
      fail_msg="$2"
      shift 2
    elif [[ "$1" == "--unchanged" ]]; then
      unchanged_msg="$2"
      shift 2
    elif [[ "$1" == "--pattern" ]]; then
      unchanged_pattern="$2"
      shift 2
    fi
  done

  local cmd_and_args=("$@")

  local pid
  local delay=0.1
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local temp_output_file
  local spinner_color="${YELLOW:-$(tput setaf 3)}"

  temp_output_file=$(mktemp "${TMPDIR:-/tmp}/spinner_output.XXXXXX")

  tput civis

  echo -ne "${spinner_color}${spinstr:0:1}${RESET} ${NORMAL}${msg}${RESET}"

  "${cmd_and_args[@]}" >"$temp_output_file" 2>"$temp_output_file" &
  pid=$!

  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(((i + 1) % ${#spinstr}))
    echo -ne "$(tput cr)${spinner_color}${spinstr:$i:1}${RESET} ${NORMAL}${msg}${RESET}"
    sleep "$delay"
  done

  wait "$pid"
  local cmd_exit_status=$?

  echo -ne "$(tput cr)$(tput el)"

  tput cnorm

  local final_success_msg="${success_msg:-${msg} completed.}"
  local final_fail_msg="${fail_msg:-${msg} failed.}"
  local final_unchanged_msg="${unchanged_msg:-${msg} (no changes needed).}"

  local return_status=$cmd_exit_status
  if [ "$cmd_exit_status" -eq 0 ]; then
    if [[ -n "$unchanged_pattern" && -s "$temp_output_file" ]] && grep -qE -- "$unchanged_pattern" "$temp_output_file"; then
      success_tick_msg "$final_unchanged_msg"
      return_status=100
    else
      success_tick_msg "$final_success_msg"
    fi
  else
    error_msg "$final_fail_msg"
    _print_temp_output_if_exists "$temp_output_file"
  fi

  rm -f "$temp_output_file"

  return "$return_status"
}

# Operation wrapper with timing
run_operation() {
  local operation_name="$1"
  shift

  action_msg "Starting $operation_name..."
  local start_time
  start_time=$(date +%s)

  if "$@"; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    success_tick_msg "$operation_name completed (${duration}s)"
    return 0
  else
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    error_msg "$operation_name failed (${duration}s)"
    return 1
  fi
}

# Step header with optional numbering
step_header() {
  local step_name="$1"
  local step_count="${2:-}"
  local total_steps="${3:-}"

  if [[ -n "$step_count" && -n "$total_steps" ]]; then
    title "$step_name (${step_count}/${total_steps})"
  else
    title "$step_name"
  fi
}

# Package operation wrapper
run_package_operation() {
  local package_name="$1"
  local operation="$2"
  local spinner_msg="$3"
  local success_msg="${4:-Successfully ${operation}ed $package_name.}"
  local fail_msg="${5:-Failed to ${operation} $package_name.}"
  local unchanged_msg="${6:-$package_name is already up to date.}"
  shift 6

  if [[ "$1" == "--pattern" ]]; then
    local pattern="$2"
    shift 2
    ui_spinner "$spinner_msg" \
      --success "$success_msg" \
      --fail "$fail_msg" \
      --unchanged "$unchanged_msg" \
      --pattern "$pattern" \
      "$@"
  else
    ui_spinner "$spinner_msg" \
      --success "$success_msg" \
      --fail "$fail_msg" \
      --unchanged "$unchanged_msg" \
      "$@"
  fi
}

# Show final summary with errors and warnings
show_final_summary() {
  local operation="$1"
  local target="${2:-}"
  local success="${3:-true}"
  local start_time="${4:-}"

  # Calculate duration if start time provided
  local duration_text=""
  if [[ -n "$start_time" ]]; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    duration_text=" (${duration}s)"
  fi

  if [[ "$success" == "true" && $MEOW_ERROR_COUNT -eq 0 ]]; then
    if [[ -n "$target" ]]; then
      success_tick_msg "$operation '$target' completed successfully$duration_text"
    else
      success_tick_msg "$operation completed successfully$duration_text"
    fi
  else
    if [[ -n "$target" ]]; then
      error_msg "$operation '$target' finished with errors$duration_text"
    else
      error_msg "$operation finished with errors$duration_text"
    fi
  fi

  # Show summary counts
  local summary_parts=()
  if [[ $MEOW_ERROR_COUNT -gt 0 ]]; then
    summary_parts+=("${MEOW_ERROR_COUNT} error$([ $MEOW_ERROR_COUNT -gt 1 ] && echo "s" || true)")
  fi
  if [[ $MEOW_WARNING_COUNT -gt 0 ]]; then
    summary_parts+=("${MEOW_WARNING_COUNT} warning$([ $MEOW_WARNING_COUNT -gt 1 ] && echo "s" || true)")
  fi

  if [[ ${#summary_parts[@]} -gt 0 ]]; then
    local summary_text
    summary_text=$(IFS=", "; echo "${summary_parts[*]}")
    if [[ $MEOW_ERROR_COUNT -gt 0 ]]; then
      error "Summary: $summary_text"
    else
      warning "Summary: $summary_text"
    fi

    # Show detailed errors and warnings in verbose mode or if there are errors
    if [[ "$MEOW_VERBOSE" == "true" || $MEOW_ERROR_COUNT -gt 0 ]]; then
      if [[ ${#MEOW_ERRORS[@]} -gt 0 ]]; then
        echo ""
        error "Errors encountered:"
        for err in "${MEOW_ERRORS[@]}"; do
          list_item_msg "$err"
        done
      fi

      if [[ "$MEOW_VERBOSE" == "true" && ${#MEOW_WARNINGS[@]} -gt 0 ]]; then
        echo ""
        warning "Warnings encountered:"
        for warn in "${MEOW_WARNINGS[@]}"; do
          list_item_msg "$warn"
        done
      fi
    fi
  fi
  return 0
}

# Reset error/warning counters (for use in tests or multiple operations)
reset_summary_counters() {
  MEOW_ERROR_COUNT=0
  MEOW_WARNING_COUNT=0
  MEOW_ERRORS=()
  MEOW_WARNINGS=()
}
