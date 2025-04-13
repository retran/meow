#!/usr/bin/env bash

# lib/core/ui.sh - Core UI functions for terminal output

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_UI_SOURCED=1

source "${DOTFILES_DIR}/lib/core/colors.sh"

# Indent helper for all logging
indent() {
  local level="${1:-0}"
  local indent_str=""
  for ((i=0; i<level; i++)); do
    indent_str+="  "
  done
  echo -n "$indent_str"
}

# Helper for basic colored messages
_base_msg() {
  local indent_level="$1"
  local color_prefix="$2"
  shift 2
  echo -e "$(indent "$indent_level")${color_prefix}${*}${RESET}"
}

# Helper for messages with icons
_icon_msg_core() {
  local indent_level="$1"
  local icon_and_color="$2"
  shift 2
  echo -e "$(indent "$indent_level")${icon_and_color}${RESET}${NORMAL}${*}${RESET}"
}

# Helper function to print temporary output file content on error (used by ui_spinner)
_print_temp_output_if_exists() {
  local indent_level="$1"
  local temp_file="$2"
  if [[ -s "$temp_file" ]]; then
    echo ""
    error "$indent_level" "Output:"
    while IFS= read -r line; do
        content "$indent_level" "$line"
    done < "$temp_file"
  fi
}

msg() { _base_msg "${1:-0}" "${NORMAL}" "${@:2}"; }
success() { _base_msg "${1:-0}" "${SUCCESS}" "${@:2}"; }
error() { _base_msg "${1:-0}" "${ERROR}" "${@:2}" >&2; }
warning() { _base_msg "${1:-0}" "${WARNING}" "${@:2}"; }
info() { _base_msg "${1:-0}" "${INFO}" "${@:2}"; }
content() { _base_msg "${1:-0}" "${CONTENT}" "${@:2}"; }

title() { _base_msg "${1:-0}" "${HEADER}${BOLD}" "${@:2}"; }
header() { _base_msg "${1:-0}" "${HEADER}" "${@:2}"; }
subheader() { _base_msg "${1:-0}" "${SUBHEADER}" "${@:2}"; }

action_msg() { _icon_msg_core "${1:-0}" "${INFO}➤ " "${@:2}"; }
success_tick_msg() { _icon_msg_core "${1:-0}" "${SUCCESS}✓ " "${@:2}"; }
info_italic_msg() { _icon_msg_core "${1:-0}" "${INFO}ℹ︎ " "${@:2}"; }
dependency_msg() { _icon_msg_core "${1:-0}" "${NORMAL}↪ " "${@:2}"; }
indented_info() { _icon_msg_core "${1:-0}" "${NORMAL}  " "${@:2}"; }
indented_success_tick_msg() { _icon_msg_core "${1:-0}" "${SUCCESS}  ✓ " "${@:2}"; }
indented_warning() { _icon_msg_core "${1:-0}" "${WARNING}  ⚠ " "${@:2}"; }
indented_error_msg() { _icon_msg_core "${1:-0}" "${ERROR}  ✗ " "${@:2}" >&2; }
list_item_msg() { _icon_msg_core "${1:-0}" "${NORMAL}    " "${@:2}"; }
emphasized_msg() { _icon_msg_core "${1:-0}" "${BOLD}" "${@:2}"; }

ui_confirm() {
  local indent_level="${1:-0}"
  local message="${2:-Confirm}"
  local default_response="${3:-N}"
  local prompt_suffix
  local default_upper

  # Convert to uppercase in a portable way
  default_upper=$(echo "$default_response" | tr '[:lower:]' '[:upper:]')

  case "$default_upper" in
    Y|YES)
      prompt_suffix="(Y/n)"
      ;;
    *)
      prompt_suffix="(y/N)"
      ;;
  esac

  local response
  while true; do
    echo -ne "$(indent "$indent_level")${INFO}❓ ${RESET}${NORMAL}${message} ${prompt_suffix} ${RESET}"
    read -r response </dev/tty

    if [[ -z "$response" ]]; then
      response="$default_response"
    fi

    # Convert response to uppercase in a portable way
    local response_upper
    response_upper=$(echo "$response" | tr '[:lower:]' '[:upper:]')

    case "$response_upper" in
      Y|YES)
        return 0
        ;;
      N|NO)
        return 1
        ;;
      *)
        warning "$indent_level" "Please answer 'y' for yes or 'n' for no."
        ;;
    esac
  done
}

# Spinner function
# Usage: ui_spinner <indent_level> "Message for spinner" [--success "Success message"] [--fail "Failure message"] [--unchanged "Unchanged message"] [--pattern "Unchanged pattern"] command [arg1 arg2 ...]
# Example: ui_spinner 1 "Installing package..." brew install package_name
# Example with custom messages: ui_spinner 1 "Installing package..." --success "Package installed!" --fail "Package installation failed!" --unchanged "Package already up to date!" brew install package_name
# Returns the exit code of the command
ui_spinner() {
  local indent_level="$1"
  local msg="$2"
  shift 2

  local success_msg=""
  local fail_msg=""
  local unchanged_msg=""
  local unchanged_pattern=""

  while [[ "$1" == "--success" || "$1" == "--fail" || "$1" == "--unchanged" || "$1" == "--pattern" ]]; do
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

  echo -ne "$(indent "$indent_level")${spinner_color}${spinstr:0:1}${RESET} ${NORMAL}${msg}${RESET}"

  "${cmd_and_args[@]}" >"$temp_output_file" 2>"$temp_output_file" &
  pid=$!

  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(((i + 1) % ${#spinstr}))
    echo -ne "$(tput cr)$(indent "$indent_level")${spinner_color}${spinstr:$i:1}${RESET} ${NORMAL}${msg}${RESET}"
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
  if [ $cmd_exit_status -eq 0 ]; then
    if [[ -n "$unchanged_pattern" && -s "$temp_output_file" ]] && grep -qE -- "$unchanged_pattern" "$temp_output_file"; then
      success_tick_msg "$indent_level" "$final_unchanged_msg"
      return_status=100
    else
      success_tick_msg "$indent_level" "$final_success_msg"
    fi
  else
    indented_error_msg "$indent_level" "$final_fail_msg"
    _print_temp_output_if_exists "$indent_level" "$temp_output_file"
  fi

  rm -f "$temp_output_file"

  return $return_status
}

log_verbose() {
  if [[ "${VERBOSE:-0}" -eq 1 || "${DEBUG:-0}" -eq 1 ]]; then
    echo "$(indent "${1:-0}")${MAGENTA}VERBOSE:${RESET} ${*:2}" >&2
  fi
}

# Standard operation wrapper with consistent logging
# Usage: run_operation <indent_level> <operation_name> <command> [args...]
run_operation() {
  local indent_level="$1"
  local operation_name="$2"
  shift 2

  action_msg "$indent_level" "Starting $operation_name..."
  local start_time
  start_time=$(date +%s)

  if "$@"; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    success_tick_msg "$indent_level" "$operation_name completed (${duration}s)"
    return 0
  else
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    indented_error_msg "$indent_level" "$operation_name failed (${duration}s)"
    return 1
  fi
}

# Standardized step logging for multi-step operations
step_header() {
  local indent_level="$1"
  local step_name="$2"
  local step_count="${3:-}"
  local total_steps="${4:-}"

  if [[ -n "$step_count" && -n "$total_steps" ]]; then
    title "$indent_level" "$step_name (${step_count}/${total_steps})"
  else
    title "$indent_level" "$step_name"
  fi
}

# Standardized package operation wrapper
run_package_operation() {
  local indent_level="$1"
  local package_name="$2"
  local operation="$3"
  local spinner_msg="$4"
  local success_msg="${5:-Successfully ${operation}ed $package_name.}"
  local fail_msg="${6:-Failed to ${operation} $package_name.}"
  local unchanged_msg="${7:-$package_name is already up to date.}"
  shift 7

  if [[ "$1" == "--pattern" ]]; then
    local pattern="$2"
    shift 2
    ui_spinner "$indent_level" "$spinner_msg" \
      --success "$success_msg" \
      --fail "$fail_msg" \
      --unchanged "$unchanged_msg" \
      --pattern "$pattern" \
      "$@"
  else
    ui_spinner "$indent_level" "$spinner_msg" \
      --success "$success_msg" \
      --fail "$fail_msg" \
      --unchanged "$unchanged_msg" \
      "$@"
  fi
}
