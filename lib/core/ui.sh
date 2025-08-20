#!/usr/bin/env bash

# lib/core/ui.sh - UI functions for terminal output

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_UI_SOURCED=1

source "${MEOW}/lib/core/colors.sh"

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
    echo ""
    error "Command output:"
    while IFS= read -r line; do
      content "$line"
    done <"$temp_file"
  fi
}

# Message functions
msg() { _base_msg "${NORMAL}" "$@"; }
success() { _base_msg "${SUCCESS}" "$@"; }
error() { _base_msg "${ERROR}" "$@" >&2; }
warning() { _base_msg "${WARNING}" "$@"; }
info() { _base_msg "${INFO}" "$@"; }
content() { _base_msg "${CONTENT}" "$@"; }

# Header functions
title() { _base_msg "${HEADER}${BOLD}" "$@"; }
header() { _base_msg "${HEADER}" "$@"; }
subheader() { _base_msg "${SUBHEADER}" "$@"; }

# Icon messages
action_msg() { _icon_msg_core "${INFO}➤ " "$@"; }
success_tick_msg() { _icon_msg_core "${SUCCESS}✓ " "$@"; }
info_italic_msg() { _icon_msg_core "${INFO}ℹ︎ " "$@"; }
dependency_msg() { _icon_msg_core "${NORMAL}↪ " "$@"; }
error_msg() { _icon_msg_core "${ERROR}  ✗ " "$@" >&2; }
list_item_msg() { _icon_msg_core "${NORMAL}    " "$@"; }
emphasized_msg() { _icon_msg_core "${BOLD}" "$@"; }

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
