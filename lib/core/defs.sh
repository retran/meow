#!/usr/bin/env bash

# Check if script is sourced or executed. If sourced, prevent re-execution if already loaded.
if [[ -n "${_LIB_DEFS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_DEFS_SOURCED=1

# Strict mode: exit on error, unset variables, and pipefail

# Global flags
VERBOSE=0
DRY_RUN=0

# Spinner variables
_spinner_pid=""
_spinner_char_idx=0
_spinner_chars=("-" "\\" "|" "/") # Bash 3.2 compatible array

# --- Utility Functions ---

# Function to print messages to stderr
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
  return 1 # Indicate error for set -e
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

# Handles script exit on error, ensuring spinner is stopped.
error_exit() {
  local code=$?
  local line_num="${BASH_LINENO[0]}"
  local cmd="${BASH_COMMAND}"

  # If a spinner is running, stop it before exiting
  if [[ -n "${_spinner_pid}" ]]; then
    _stop_spinner
    printf "\n" >&2 # Add a newline after the spinner if it was stopped
  fi

  # Only report error if exit code is non-zero
  if [[ "$code" -ne 0 ]]; then
    log_error "Command '${cmd}' failed with exit code ${code} on line ${line_num}."
  fi
  exit "$code"
}

# Trap ERR to call error_exit, ensuring cleanup before exit.
trap error_exit ERR

# Ensure a directory exists, creating it if necessary
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

# Portable way to get the immediate target of a symlink.
# Behaves consistently on Linux and macOS readlink for this purpose.
get_link_target() {
  local file="$1"
  if [[ -L "$file" ]]; then
    readlink "$file"
  else
    printf "%s\n" "$file" # Not a symlink, return original path
  fi
}

# --- Spinner Function ---
# This function replaces any previous parse_spinner_messages by directly managing messages.

_start_spinner() {
  local msg="$1"
  # Use a subshell to run the spinner, so it doesn't block the main script
  (
    # Disable error handling in spinner subshell
    set +e
    local i=0
    local num_chars=${#_spinner_chars[@]} # Get array length in Bash 3.2
    while true; do
      printf "\r%s %s" "${_spinner_chars[i % num_chars]}" "$msg"
      i=$(((i + 1) % num_chars)) # Bash 3.2 compatible arithmetic
      sleep 0.1
    done
  ) &
  _spinner_pid=$!
  # Ensure spinner stops on any script exit, including clean exit
  trap "_stop_spinner; exit 0" EXIT # Re-trap EXIT to ensure spinner stops cleanly
}

_stop_spinner() {
  if [[ -n "${_spinner_pid}" ]]; then
    kill "$_spinner_pid" >/dev/null 2>&1 || true # Kill the spinner process
    wait "$_spinner_pid" >/dev/null 2>&1 || true # Wait for it to terminate
    _spinner_pid=""
    # Clear the spinner line by overwriting with spaces and then return cursor
    printf "\r%$(tput cols 2>/dev/null || printf "80")s\r" "" >&2 # Use tput cols for width, fallback to 80
    trap error_exit ERR                                           # Restore original error trap
  fi
}

# --- Core Logic Functions ---

# Function to create a symlink from a source to a destination.
# $1: Source path (absolute recommended for consistency).
# $2: Destination path (where the link will be created).
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
      # For absolute paths, direct comparison is reliable.
      # readlink with absolute source path will return absolute target path.
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

# Function to remove a path (symlink or file/directory).
# $1: Path to remove.
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
    if ! rm -rf "$path_to_remove"; then # Use -rf for recursive removal of directories/symlinks
      _stop_spinner
      log_error "Failed to remove '$path_to_remove'."
      return 1
    fi
    _stop_spinner
    log_info "Successfully removed '$display_name'."
  fi
  return 0
}

# Install a preset by creating a symlink.
# $1: preset name
install_preset() {
  local preset_name="$1"
  local source_path="${MEOW_PRESETS_DIR}/${preset_name}"
  local dest_path="${MEOW_INSTALLED_PRESETS_DIR}/${preset_name}"

  log_info "Installing preset: '$preset_name'"
  link_file "$source_path" "$dest_path" || return 1
  log_info "Preset '$preset_name' installed."
  return 0
}

# Uninstall a preset by removing its symlink.
# $1: preset name
uninstall_preset() {
  local preset_name="$1"
  local dest_path="${MEOW_INSTALLED_PRESETS_DIR}/${preset_name}"

  log_info "Uninstalling preset: '$preset_name'"
  remove_path "$dest_path" || return 1
  log_info "Preset '$preset_name' uninstalled."
  return 0
}

# Install a component by creating a symlink.
# $1: component name
install_component() {
  local component_name="$1"
  local source_path="${MEOW_COMPONENTS_DIR}/${component_name}"
  local dest_path="${MEOW_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Installing component: '$component_name'"
  link_file "$source_path" "$dest_path" || return 1
  log_info "Component '$component_name' installed."
  return 0
}

# Uninstall a component by removing its symlink.
# $1: component name
uninstall_component() {
  local component_name="$1"
  local dest_path="${MEOW_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Uninstalling component: '$component_name'"
  remove_path "$dest_path" || return 1
  log_info "Component '$component_name' uninstalled."
  return 0
}

# Manually install a component by copying it.
# $1: component name
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
    if ! cp -R "$source_path" "$dest_path"; then # -R for recursive copy
      _stop_spinner
      log_error "Failed to copy '$source_path' to '$dest_path'."
      return 1
    fi
    _stop_spinner
    log_info "Successfully copied '$component_name' to '$dest_path'."
  fi
  return 0
}

# Uninstall a manually installed component by removing the copied file/directory.
# $1: component name
manual_uninstall_component() {
  local component_name="$1"
  local dest_path="${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}/${component_name}"

  log_info "Uninstalling manual component: '$component_name'"
  remove_path "$dest_path" || return 1
  log_info "Manual component '$component_name' uninstalled."
  return 0
}

# List installed components/presets.
# $1: type ("presets", "components", or "manual-components")
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
  # Use find for listing to handle directories and files robustly,
  # and avoid issues with shell globbing if there are many items or unusual characters.
  # For Bash 3.2, no readarray. Use while read.
  # find's output is piped to sort for consistent ordering, then to while read.
  while IFS= read -r item; do
    if [[ -n "$item" ]]; then # Ensure item is not empty
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

# --- Argument Parsing ---

# Show usage information
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

# Parse command line arguments
parse_args() {
  local cmd_executed=0 # Flag to indicate if a command has been found and executed

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
            break # Exit loop after command execution
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
      --) # End of options
        shift
        break
        ;;
      -*) # Unknown option
        log_error "Unknown option: '$1'"
        usage
        ;;
      *) # Positional argument (should be a command if not already processed)
        log_error "Unknown command or argument: '$1'"
        usage
        ;;
    esac
  done

  # If no command was executed by this point, show usage.
  if [[ "$cmd_executed" -eq 0 ]]; then
    log_error "No command specified or executed."
    usage
  fi
  exit 0 # Exit successfully after command execution
}

# --- Main Execution ---

# Ensure MEOW environment variable is set.
if [[ -z "${MEOW:-}" ]]; then
  log_error "MEOW environment variable is not set. Please set it to the root directory of your MEOW installation."
  exit 1
fi

# Ensure MEOW directory exists and make it an absolute path.
# This is crucial for consistent symlink targets and path resolution.
if [[ ! -d "$MEOW" ]]; then
  log_error "MEOW directory does not exist: '$MEOW'"
  exit 1
fi
# Get absolute path for MEOW; portable for Bash 3.2
MEOW="$(cd "$MEOW" && pwd)" || error_exit
log_info "MEOW_HOME set to: '$MEOW'"

# Define readonly directories AFTER MEOW has been absolutized.
# This ensures all paths are absolute and consistent.
readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_INSTALLED_PRESETS_DIR="${MEOW}/.installed/presets"

readonly MEOW_COMPONENTS_DIR="${MEOW}/components"
readonly MEOW_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components"
readonly MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components-manual"

readonly MEOW_DOWNLOADS_DIR="${MEOW}/.downloads"

# Ensure base directories exist (source directories might not exist if empty)
ensure_dir_exists "$MEOW_PRESETS_DIR" || error_exit
ensure_dir_exists "$MEOW_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_INSTALLED_PRESETS_DIR" || error_exit
ensure_dir_exists "$MEOW_INSTALLED_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR" || error_exit
ensure_dir_exists "$MEOW_DOWNLOADS_DIR" || error_exit

# Call argument parser. It will execute commands and exit.
parse_args "$@"
