#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_UI_SOURCED=1

if [[ -z "${MEOW:-}" ]]; then
  echo "Error: MEOW environment variable is not set. Cannot source core UI dependencies (e.g., colors.sh)." >&2
  exit 1
fi

source "${MEOW}/lib/core/colors.sh"

MEOW_VERBOSE="${MEOW_VERBOSE:-false}"
MEOW_DRY_RUN="${MEOW_DRY_RUN:-false}"

MEOW_ERROR_COUNT=0
MEOW_WARNING_COUNT=0
MEOW_ERRORS=()
MEOW_WARNINGS=()

_f() {
  local template="$1"
  shift
  printf -- "$template" "$@"
}

_base_msg() {
  local color_prefix="$1"
  shift
  printf "%b\n" "${color_prefix}$*${RESET}"
}

_icon_msg_core() {
  local icon_and_color="$1"
  shift
  printf "%b\n" "${icon_and_color}${NORMAL}$*${RESET}"
}

ui_message() { _base_msg "${NORMAL}" "$@"; }
ui_success() { _base_msg "${SUCCESS}" "$@"; }
ui_info() { _base_msg "${INFO}" "$@"; }
ui_content() { _base_msg "${CONTENT}" "$@"; }

ui_error() {
  _base_msg "${ERROR}" "$@" >&2
  MEOW_ERROR_COUNT=$((MEOW_ERROR_COUNT + 1))
  MEOW_ERRORS+=("$*")
}

ui_warning() {
  _base_msg "${WARNING}" "$@"
  MEOW_WARNING_COUNT=$((MEOW_WARNING_COUNT + 1))
  MEOW_WARNINGS+=("$*")
}

ui_verbose_message() {
  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_message "$@"
  fi
}
ui_verbose_info() {
  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_info "$@"
  fi
}

ui_title() { _base_msg "${HEADER}${BOLD}" "$@"; }
ui_header() { _base_msg "${HEADER}" "$@"; }
ui_subheader() { _base_msg "${SUBHEADER}" "$@"; }

ui_step_header() {
  local step_name="$1"
  local step_count="${2:-}"
  local total_steps="${3:-}"

  if [[ -n "$step_count" ]] && [[ -n "$total_steps" ]]; then
    ui_title "$(printf "%s (%s/%s)" "$step_name" "$step_count" "$total_steps")"
  else
    ui_title "$step_name"
  fi
}

ui_action_start() { _icon_msg_core "${INFO}➤ " "$@"; }
ui_action_success() { _icon_msg_core "${SUCCESS}✓ " "$@"; }

ui_action_error() {
  _icon_msg_core "${ERROR}✗ " "$@" >&2
  MEOW_ERROR_COUNT=$((MEOW_ERROR_COUNT + 1))
  MEOW_ERRORS+=("$*")
}

ui_action_warning() {
  _icon_msg_core "${WARNING}⚠️ " "$@"
  MEOW_WARNING_COUNT=$((MEOW_WARNING_COUNT + 1))
  MEOW_WARNINGS+=("$*")
}

ui_info_detail() { _icon_msg_core "${INFO}ℹ︎ " "$@"; }
ui_dependency() { _icon_msg_core "${NORMAL}↪ " "$@"; }
ui_list_item() { _icon_msg_core "${NORMAL}    " "$@"; }
ui_emphasis() { _icon_msg_core "${BOLD}" "$@"; }
ui_indent() { _icon_msg_core "${NORMAL}  ↳ " "$@"; }

ui_verbose_action_start() {
  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_action_start "$@"
  fi
}
ui_verbose_action_success() {
  if [[ "$MEOW_VERBOSE" = "true" ]]; then
    ui_action_success "$@"
  fi
}

ui_component_installing() {
  local component="$1"
  ui_action_start "$(printf "Installing component: %s" "$component")"
}

ui_component_updating() {
  local component="$1"
  ui_action_start "$(printf "Updating component: %s" "$component")"
}

ui_component_uninstalling() {
  local component="$1"
  ui_action_start "$(printf "Uninstalling component: %s" "$component")"
}

ui_package_manager_setup() {
  local manager="$1"
  _base_msg "${BLUE}" "$(printf "Setting up %s package manager" "$manager")"
}

ui_package_manager_ready() {
  local manager="$1"
  ui_action_success "$(printf "%s package manager ready" "$manager")"
}

ui_package_manager_cleaning() {
  local manager="$1"
  _base_msg "${YELLOW}" "$(printf "Cleaning %s package manager" "$manager")"
}

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
    printf "%b" "${INFO}❓ ${RESET}${NORMAL}${message} ${prompt_suffix} ${RESET}"
    read -r response </dev/tty

    if [[ -z "$response" ]]; then
      response="$default_response"
    fi

    local response_upper
    response_upper=$(echo "$response" | tr '[:lower:]' '[:upper:]')

    case "$response_upper" in
      Y | YES) return 0 ;;
      N | NO) return 1 ;;
      *) ui_warning "Please answer 'y' for yes or 'n' for no." ;;
    esac
  done
}

ui_silent_spinner() {
  local msg="$1"
  shift

  local temp_output_file
  temp_output_file=$(mktemp "${TMPDIR:-/tmp}/spinner_output.XXXXXX") || {
    ui_error "Failed to create temporary file for spinner."
    return 1
  }

  {
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    local spinner_color="${YELLOW:-$(tput setaf 3)}"
    tput civis || true
    while true; do
      local char="${spinner_chars:$((i % ${#spinner_chars})):1}"
      printf "\r%b%s%b %s" "${spinner_color}" "$char" "${RESET}" "$msg"
      sleep 0.1
      i=$((i + 1))
    done
  } &
  local spinner_pid=$!

  "$@" >"$temp_output_file" 2>&1 &
  local cmd_pid=$!

  wait "$cmd_pid"
  local cmd_exit_status=$?

  kill "$spinner_pid" 2>/dev/null || true
  wait "$spinner_pid" 2>/dev/null || true

  printf "\r%s" "$(tput el)"
  tput cnorm || true

  rm -f "$temp_output_file"
  return "$cmd_exit_status"
}

ui_spinner() {
  local msg="$1"
  shift

  local success_msg=""
  local fail_msg=""
  local unchanged_msg=""
  local unchanged_pattern=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --success)
        success_msg="$2"
        shift 2
        ;;
      --fail)
        fail_msg="$2"
        shift 2
        ;;
      --unchanged)
        unchanged_msg="$2"
        shift 2
        ;;
      --pattern)
        unchanged_pattern="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  local cmd_and_args=("$@")

  local pid
  local delay=0.1
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local temp_output_file
  local spinner_color="${YELLOW:-$(tput setaf 3)}"

  temp_output_file=$(mktemp "${TMPDIR:-/tmp}/spinner_output.XXXXXX") || {
    ui_error "Failed to create temporary file for spinner output."
    return 1
  }

  tput civis || true

  printf "%b%s%b %b%s%b" "${spinner_color}" "${spinstr:0:1}" "${RESET}" "${NORMAL}" "$msg" "${RESET}"

  if [[ "$MEOW_DRY_RUN" = "true" ]]; then
    ui_info_detail "$(printf "Dry run: Skipping execution of '%s'" "${cmd_and_args[*]}")"
    cmd_exit_status=0
    printf "" >"$temp_output_file" # Ensure file exists but is empty for dry run
  else
    "${cmd_and_args[@]}" >"$temp_output_file" 2>&1 &
    pid=$!

    local i=0
    while kill -0 "$pid" 2>/dev/null; do
      i=$(((i + 1) % ${#spinstr}))
      printf "\r%b%s%b %b%s%b" "${spinner_color}" "${spinstr:$i:1}" "${RESET}" "${NORMAL}" "$msg" "${RESET}"
      sleep "$delay"
    done

    wait "$pid"
    cmd_exit_status=$?
  fi

  printf "\r%s" "$(tput el)"

  tput cnorm || true

  local final_success_msg="${success_msg:-${msg} completed successfully.}"
  local final_fail_msg="${fail_msg:-${msg} failed.}"
  local final_unchanged_msg="${unchanged_msg:-${msg} (no changes needed).}"

  local return_status=$cmd_exit_status
  if [ "$cmd_exit_status" -eq 0 ]; then
    if [[ -n "$unchanged_pattern" ]] && [ -s "$temp_output_file" ] && grep -qE -- "$unchanged_pattern" "$temp_output_file"; then
      ui_action_success "$final_unchanged_msg"
      return_status=100
    else
      ui_action_success "$final_success_msg"
    fi
  else
    ui_action_error "$final_fail_msg"

    if [ -s "$temp_output_file" ]; then
      if [[ "$MEOW_VERBOSE" = "true" ]]; then
        ui_error "Command output:"
        while IFS= read -r line; do
          ui_content "$line"
        done <"$temp_output_file"
      else
        ui_error "Command failed. For detailed output, rerun with --verbose."
        head -n 3 "$temp_output_file" | while IFS= read -r line; do
          ui_content "$line"
        done
        local line_count
        line_count=$(wc -l <"$temp_output_file")
        if [ "$line_count" -gt 3 ]; then
          ui_info "$(printf "%d more lines hidden. Rerun with --verbose for full output." $((line_count - 3)))"
        fi
      fi
    else
      ui_info "No output captured from the command."
    fi
  fi

  rm -f "$temp_output_file"

  return "$return_status"
}

run_package_operation() {
  local package_name="$1"
  local operation="$2"
  local spinner_msg="$3"
  local success_msg="${4:-Successfully ${operation}ed $package_name.}"
  local fail_msg="${5:-Failed to ${operation} $package_name.}"
  local unchanged_msg="${6:-$package_name is already up to date.}"
  shift 6

  local pattern_arg=()
  if [[ "$1" = "--pattern" ]]; then
    pattern_arg=("$1" "$2")
    shift 2
  fi

  ui_spinner "$spinner_msg" \
    --success "$success_msg" \
    --fail "$fail_msg" \
    --unchanged "$unchanged_msg" \
    "${pattern_arg[@]}" \
    "$@"
}

show_final_summary() {
  local operation="$1"
  local target="${2:-}"
  local success="${3:-true}"
  local start_time="${4:-}"

  local duration_text=""
  if [[ -n "$start_time" ]]; then
    local end_time
    end_time=$(date "+%s")
    local duration=$((end_time - start_time))
    duration_text=" (completed in ${duration}s)"
  fi

  if [[ "$success" = "true" ]] && [ "$MEOW_ERROR_COUNT" -eq 0 ]; then
    if [[ -n "$target" ]]; then
      ui_action_success "$(printf "%s '%s' completed successfully%s" "$operation" "$target" "$duration_text")"
    else
      ui_action_success "$(printf "%s completed successfully%s" "$operation" "$duration_text")"
    fi
  else
    if [[ -n "$target" ]]; then
      ui_action_error "$(printf "%s '%s' finished with errors%s" "$operation" "$target" "$duration_text")"
    else
      ui_action_error "$(printf "%s finished with errors%s" "$operation" "$duration_text")"
    fi
  fi

  local summary_parts=()
  if [ "$MEOW_ERROR_COUNT" -gt 0 ]; then
    summary_parts+=("$(printf "%d error%s" "$MEOW_ERROR_COUNT" "$([ "$MEOW_ERROR_COUNT" -gt 1 ] && echo "s")")")
  fi
  if [ "$MEOW_WARNING_COUNT" -gt 0 ]; then
    summary_parts+=("$(printf "%d warning%s" "$MEOW_WARNING_COUNT" "$([ "$MEOW_WARNING_COUNT" -gt 1 ] && echo "s")")")
  fi

  if [ "${#summary_parts[@]}" -gt 0 ]; then
    local summary_text_builder=""
    local i=0
    for part in "${summary_parts[@]}"; do
      if [ "$i" -gt 0 ]; then
        summary_text_builder="${summary_text_builder}, "
      fi
      summary_text_builder="${summary_text_builder}${part}"
      i=$((i + 1))
    done
    local summary_text="${summary_text_builder}"

    if [ "$MEOW_ERROR_COUNT" -gt 0 ]; then
      ui_error "Summary: $summary_text"
    else
      ui_warning "Summary: $summary_text"
    fi

    if [[ "$MEOW_VERBOSE" = "true" ]] || [ "$MEOW_ERROR_COUNT" -gt 0 ]; then
      if [ "${#MEOW_ERRORS[@]}" -gt 0 ]; then
        ui_error "Errors encountered:"
        for err_msg in "${MEOW_ERRORS[@]}"; do
          ui_list_item "$err_msg"
        done
      fi

      if [[ "$MEOW_VERBOSE" = "true" ]] && [ "${#MEOW_WARNINGS[@]}" -gt 0 ]; then
        ui_warning "Warnings encountered (verbose mode):"
        for warn_msg in "${MEOW_WARNINGS[@]}"; do
          ui_list_item "$warn_msg"
        done
      fi
    fi
  fi
  return 0
}

reset_summary_counters() {
  MEOW_ERROR_COUNT=0
  MEOW_WARNING_COUNT=0
  MEOW_ERRORS=()
  MEOW_WARNINGS=()
}
