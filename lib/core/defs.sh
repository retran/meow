#!/usr/bin/env bash

if [[ -n "${_LIB_DEFS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_DEFS_SOURCED=1

VERBOSE=0
DRY_RUN=0

_spinner_pid=""
_spinner_chars=("-" "\\" "|" "/")

log_message() {
  local level="$1"
  local message="$2"
  printf "[%s] %s\n" "$level" "$message" >&2
}

log_info() {
  log_message "INFO" "$1"
}

log_warn() {
  log_message "WARN" "$1"
}

log_error() {
  log_message "ERROR" "$1"
  return 1
}

verbose_log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    log_message "VERB" "$1"
  fi
}

dry_run_log() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_message "DRY RUN" "$1"
  fi
}

error_exit() {
  local code=$?
  local line_num="${BASH_LINENO[0]}"
  local cmd="${BASH_COMMAND}"

  if [[ -n "${_spinner_pid}" ]]; then
    _stop_spinner
    printf "\n" >&2
  fi

  if [[ "$code" -ne 0 ]]; then
    log_error "Command '${cmd}' failed with exit code ${code} on line ${line_num}."
  fi
  exit "$code"
}

trap error_exit ERR

ensure_dir_exists() {
  local dir="$1"
  verbose_log "Ensuring directory exists: '$dir'"
  if [[ ! -d "$dir" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      dry_run_log "Would create directory: '$dir'"
    else
      if ! mkdir -p "$dir"; then
        log_error "Failed to create directory: '$dir'"
        return 1
      fi
    fi
  fi
  return 0
}

get_link_target() {
  local file="$1"
  if [[ -L "$file" ]]; then
    readlink "$file"
  else
    printf "%s\n" "$file"
  fi
}

_start_spinner() {
  local msg="$1"
  (
    set +e
    local i=0
    local num_chars=${#_spinner_chars[@]}
    while true; do
      printf "\r%s %s" "${_spinner_chars[i % num_chars]}" "$msg"
      i=$(((i + 1) % num_chars))
      sleep 0.1
    done
  ) &
  _spinner_pid=$!
  trap "_stop_spinner; exit 0" EXIT
}

_stop_spinner() {
  if [[ -n "${_spinner_pid}" ]]; then
    kill "$_spinner_pid" >/dev/null 2>&1 || true
    wait "$_spinner_pid" >/dev/null 2>&1 || true
    _spinner_pid=""
    printf "\r%$(tput cols 2>/dev/null || printf "80")s\r" "" >&2
    trap error_exit ERR
  fi
}

link_file() {
  local source_path="$1"
  local dest_path="$2"
  local dest_dir="$(dirname "$dest_path")"
  local target_name="$(basename "$source_path")"

  ensure_dir_exists "$dest_dir" || return 1

  verbose_log "Attempting to link '$source_path' to '$dest_path'"

  if [[ ! -e "$source_path" ]]; then
    log_error "Source file/directory does not exist: '$source_path'"
    return 1
  fi

  if [[ -e "$dest_path" ]]; then
    if [[ -L "$dest_path" ]]; then
      local existing_target="$(get_link_target "$dest_path")"
      if [[ "$existing_target" = "$source_path" ]]; then
        log_info "Link '$dest_path' already points to '$source_path'. Skipping."
        return 0
      else
        log_warn "Link '$dest_path' exists and points to a different target ('$existing_target'). Removing old link."
        if [[ "$DRY_RUN" -eq 1 ]]; then
          dry_run_log "Would remove existing link: '$dest_path'"
        else
          if ! rm "$dest_path"; then
            log_error "Failed to remove old link: '$dest_path'"
            return 1
          fi
        fi
      fi
    else
      log_warn "'$dest_path' exists and is not a symlink. Backing up and overwriting."
      if [[ "$DRY_RUN" -eq 1 ]]; then
        dry_run_log "Would backup '$dest_path' to '$dest_path.bak' and then link."
      else
        if ! mv "$dest_path" "$dest_path.bak"; then
          log_error "Failed to backup '$dest_path'."
          return 1
        fi
        log_info "Backed up '$dest_path' to '$dest_path.bak'."
      fi
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_run_log "Would create symlink: '$dest_path' -> '$source_path'"
    log_info "Dry run: Link '$target_name' from '$source_path' to '$dest_path'."
  else
    _start_spinner "Linking '$target_name'..."
    if ! ln -s "$source_path" "$dest_path"; then
      _stop_spinner
      log_error "Failed to create symlink: '$dest_path' -> '$source_path'"
      return 1
    fi
    _stop_spinner
    log_info "Successfully linked '$target_name' from '$source_path' to '$dest_path'."
  fi
  return 0
}

remove_path() {
  local path_to_remove="$1"
  local display_name="$(basename "$path_to_remove")"

  if [[ ! -e "$path_to_remove" ]]; then
    log_info "'$path_to_remove' does not exist. Skipping removal."
    return 0
  fi

  verbose_log "Attempting to remove '$path_to_remove'"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_run_log "Would remove: '$path_to_remove'"
    log_info "Dry run: Removed '$display_name'."
  else
    _start_spinner "Removing '$display_name'..."
    if ! rm -rf "$path_to_remove"; then
      _stop_spinner
      log_error "Failed to remove '$path_to_remove'."
      return 1
    fi
    _stop_spinner
    log_info "Successfully removed '$display_name'."
  fi
  return 0
}

install_preset() {
  local preset_name="$1"
  local source_path="${MEOW_PRESETS_DIR}/${preset_name}"
  local dest_path="${MEOW_INSTALLED_PRESETS_DIR}/${preset_name}"

  log_info "Installing preset: '$preset_name'"
  link_file "$source_path" "$dest_path" || return 1
  log_info "Preset '$preset_name' installed."
  return 0
}

uninstall_preset() {
  local preset_name="$1"
  local dest_path="${MEOW_INSTALLED_PRESETS_DIR}/${preset_name}"

  log_info "Uninstalling preset: '$preset_name'"
  remove_path "$dest_path" || return 1
  log_info "Preset '$preset_name' uninstalled."
  return 0
}

install_component() {
  local component_name="$1"
  local source_path="${MEOW_COMPONENTS_DIR}/${component_name}"
  local dest_path="${MEOW_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Installing component: '$component_name'"
  link_file "$source_path" "$dest_path" || return 1
  log_info "Component '$component_name' installed."
  return 0
}

uninstall_component() {
  local component_name="$1"
  local dest_path="${MEOW_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Uninstalling component: '$component_name'"
  remove_path "$dest_path" || return 1
  log_info "Component '$component_name' uninstalled."
  return 0
}

manual_install_component() {
  local component_name="$1"
  local source_path="${MEOW_COMPONENTS_DIR}/${component_name}"
  local dest_path="${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Manually installing component (copy): '$component_name'"

  if [[ ! -e "$source_path" ]]; then
    log_error "Source component does not exist: '$source_path'"
    return 1
  fi

  ensure_dir_exists "$(dirname "$dest_path")" || return 1

  if [[ -e "$dest_path" ]]; then
    log_warn "Manual component '$dest_path' already exists. Overwriting."
    if [[ "$DRY_RUN" -eq 1 ]]; then
      dry_run_log "Would remove existing file/directory: '$dest_path'"
      dry_run_log "Would copy '$source_path' to '$dest_path'."
    else
      if ! rm -rf "$dest_path"; then
        log_error "Failed to remove existing manual component: '$dest_path'"
        return 1
      fi
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_run_log "Would copy '$source_path' to '$dest_path'"
    log_info "Dry run: Manual install '$component_name' from '$source_path' to '$dest_path'."
  else
    _start_spinner "Copying '$component_name'..."
    if ! cp -R "$source_path" "$dest_path"; then
      _stop_spinner
      log_error "Failed to copy '$source_path' to '$dest_path'."
      return 1
    fi
    _stop_spinner
    log_info "Successfully copied '$component_name' to '$dest_path'."
  fi
  return 0
}

manual_uninstall_component() {
  local component_name="$1"
  local dest_path="${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Uninstalling manual component: '$component_name'"
  remove_path "$dest_path" || return 1
  log_info "Manual component '$component_name' uninstalled."
  return 0
}

list_installed() {
  local type="$1"
  local target_dir=""
  local display_name=""

  case "$type" in
    "presets")
      target_dir="${MEOW_INSTALLED_PRESETS_DIR}"
      display_name="Presets (Symlinked)"
      ;;
    "components")
      target_dir="${MEOW_INSTALLED_COMPONENTS_DIR}"
      display_name="Components (Symlinked)"
      ;;
    "manual-components")
      target_dir="${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}"
      display_name="Components (Manually Copied)"
      ;;
    *)
      log_error "Invalid list type: '$type'. Must be 'presets', 'components', or 'manual-components'."
      return 1
      ;;
  esac

  log_info "Listing $display_name in '$target_dir':"

  if [[ ! -d "$target_dir" ]]; then
    log_info "  No $display_name directory found at '$target_dir'."
    return 0
  fi

  local count=0
  while IFS= read -r item; do
    if [[ -n "$item" ]]; then
      local base_item="$(basename "$item")"
      if [[ -L "$item" ]]; then
        local target_link="$(get_link_target "$item")"
        printf "  - %s (-> %s)\n" "$base_item" "$target_link"
      else
        printf "  - %s\n" "$base_item"
      fi
      count=$((count + 1))
    fi
  done < <(find "$target_dir" -maxdepth 1 -mindepth 1 -print 2>/dev/null | sort)

  if [[ "$count" -eq 0 ]]; then
    log_info "  No $display_name found."
  fi
  return 0
}

usage() {
  printf "Usage: %s [OPTIONS] COMMAND [ARGUMENTS]\n" "$(basename "$0")"
  printf "\nOptions:\n"
  printf "  -v, --verbose          Enable verbose output.\n"
  printf "  -n, --dry-run          Show what would be done without making changes.\n"
  printf "  -h, --help             Show this help message.\n"
  printf "\nCommands:\n"
  printf "  preset install <name>          Install a MEOW preset (symlink).\n"
  printf "  preset uninstall <name>        Uninstall a MEOW preset.\n"
  printf "  component install <name>       Install a MEOW component (symlink).\n"
  printf "  component uninstall <name>     Uninstall a MEOW component.\n"
  printf "  component manual-install <name>  Manually install a MEOW component (copy).\n"
  printf "  component manual-uninstall <name> Manually uninstall a MEOW component.\n"
  printf "  list presets                   List installed presets.\n"
  printf "  list components                List installed symlinked components.\n"
  printf "  list manual-components         List installed manually copied components.\n"
  printf "\n"
  exit 0
}

parse_args() {
  local cmd_executed=0

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -v | --verbose)
        VERBOSE=1
        verbose_log "Verbose mode enabled."
        shift
        ;;
      -n | --dry-run)
        DRY_RUN=1
        dry_run_log "Dry run mode enabled. No changes will be made."
        shift
        ;;
      -h | --help)
        usage
        ;;
      preset)
        shift
        case "$1" in
          install)
            shift
            if [[ -z "$1" ]]; then
              log_error "Preset name required for install."
              usage
            fi
            install_preset "$1"
            cmd_executed=1
            break
            ;;
          uninstall)
            shift
            if [[ -z "$1" ]]; then
              log_error "Preset name required for uninstall."
              usage
            fi
            uninstall_preset "$1"
            cmd_executed=1
            break
            ;;
          *)
            log_error "Invalid preset command: '$1'"
            usage
            ;;
        esac
        ;;
      component)
        shift
        case "$1" in
          install)
            shift
            if [[ -z "$1" ]]; then
              log_error "Component name required for install."
              usage
            fi
            install_component "$1"
            cmd_executed=1
            break
            ;;
          uninstall)
            shift
            if [[ -z "$1" ]]; then
              log_error "Component name required for uninstall."
              usage
            fi
            uninstall_component "$1"
            cmd_executed=1
            break
            ;;
          manual-install)
            shift
            if [[ -z "$1" ]]; then
              log_error "Component name required for manual-install."
              usage
            fi
            manual_install_component "$1"
            cmd_executed=1
            break
            ;;
          manual-uninstall)
            shift
            if [[ -z "$1" ]]; then
              log_error "Component name required for manual-uninstall."
              usage
            fi
            manual_uninstall_component "$1"
            cmd_executed=1
            break
            ;;
          *)
            log_error "Invalid component command: '$1'"
            usage
            ;;
        esac
        ;;
      list)
        shift
        case "$1" in
          presets)
            list_installed "presets"
            cmd_executed=1
            break
            ;;
          components)
            list_installed "components"
            cmd_executed=1
            break
            ;;
          manual-components)
            list_installed "manual-components"
            cmd_executed=1
            break
            ;;
          *)
            log_error "Invalid list type: '$1'"
            usage
            ;;
        esac
        ;;
      --)
        shift
        break
        ;;
      -*)
        log_error "Unknown option: '$1'"
        usage
        ;;
      *)
        log_error "Unknown command or argument: '$1'"
        usage
        ;;
    esac
  done

  if [[ "$cmd_executed" -eq 0 ]]; then
    log_error "No command specified or executed."
    usage
  fi
  exit 0
}

if [[ -z "${MEOW:-}" ]]; then
  log_error "MEOW environment variable is not set. Please set it to the root directory of your MEOW installation."
  exit 1
fi

if [[ ! -d "$MEOW" ]]; then
  log_error "MEOW directory does not exist: '$MEOW'"
  exit 1
fi
MEOW="$(cd "$MEOW" && pwd)" || error_exit
log_info "MEOW_HOME set to: '$MEOW'"

readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_INSTALLED_PRESETS_DIR="${MEOW}/.installed/presets"

readonly MEOW_COMPONENTS_DIR="${MEOW}/components"
readonly MEOW_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components"
readonly MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components-manual"

readonly MEOW_DOWNLOADS_DIR="${MEOW}/.downloads"

ensure_dir_exists "$MEOW_PRESETS_DIR" || error_exit
ensure_dir_exists "$MEOW_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_INSTALLED_PRESETS_DIR" || error_exit
ensure_dir_exists "$MEOW_INSTALLED_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_DOWNLOADS_DIR" || error_exit

parse_args "$@"
