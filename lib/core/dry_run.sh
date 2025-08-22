#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_DRY_RUN_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_DRY_RUN_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/colors.sh"

# Check if dry-run mode is enabled
is_dry_run() {
  [[ "${MEOW_DRY_RUN:-}" == "true" ]]
}

# Wrapper for commands that should be stubbed in dry-run mode
dry_run_command() {
  local description="$1"
  shift

  if is_dry_run; then
    dry_run_ui_info "Would execute: $description"
    return 0
  else
    "$@"
  fi
}

# Show dry-run message with special formatting
dry_run_info() {
  local message="$1"
  echo -e "  ${CYAN}[DRY-RUN]${RESET} $message"
}

# Show dry-run command details with special formatting
dry_run_command_info() {
  local command="$1"
  echo -e "  ${CYAN}[DRY-RUN]${RESET}   Command: ${NORMAL}$command${RESET}"
}

# Wrapper for file operations in dry-run mode
dry_run_file_operation() {
  local operation="$1"
  local target="$2"
  local source="${3:-}"

  if is_dry_run; then
    case "$operation" in
      "create_symlink")
        dry_run_ui_info "Would create symlink: $target -> $source"
        ;;
      "create_dir")
        dry_run_ui_info "Would create directory: $target"
        ;;
      "remove_file")
        dry_run_ui_info "Would remove file: $target"
        ;;
      "remove_dir")
        dry_run_ui_info "Would remove directory: $target"
        ;;
      "backup_file")
        dry_run_ui_info "Would backup file: $target"
        ;;
      "restore_file")
        dry_run_ui_info "Would restore file: $target from $source"
        ;;
      *)
        dry_run_ui_info "Would perform file operation '$operation' on: $target"
        ;;
    esac
    return 0
  else
    return 1  # Indicates that actual operation should proceed
  fi
}

# Wrapper for package operations in dry-run mode
dry_run_package_operation() {
  local manager="$1"
  local operation="$2"
  local packages="$3"

  if is_dry_run; then
    case "$operation" in
      "install")
        dry_run_ui_info "Would install $manager packages: $packages"
        ;;
      "update")
        dry_run_ui_info "Would update $manager packages: $packages"
        ;;
      "remove")
        dry_run_ui_info "Would remove $manager packages: $packages"
        ;;
      *)
        dry_run_ui_info "Would perform $manager operation '$operation' on packages: $packages"
        ;;
    esac
    return 0
  else
    return 1  # Indicates that actual operation should proceed
  fi
}

# Wrapper for git operations in dry-run mode
dry_run_git_operation() {
  local operation="$1"
  local repo_path="$2"
  local details="${3:-}"

  if is_dry_run; then
    case "$operation" in
      "clone")
        dry_run_ui_info "Would clone repository to: $repo_path"
        if [[ -n "$details" ]]; then
          dry_run_ui_info "  Repository URL: $details"
        fi
        ;;
      "pull")
        dry_run_ui_info "Would pull updates in repository: $repo_path"
        ;;
      "checkout")
        dry_run_ui_info "Would checkout '$details' in repository: $repo_path"
        ;;
      *)
        dry_run_ui_info "Would perform git operation '$operation' in: $repo_path"
        ;;
    esac
    return 0
  else
    return 1  # Indicates that actual operation should proceed
  fi
}

# Wrapper for script execution in dry-run mode
dry_run_script_execution() {
  local script_path="$1"
  local description="${2:-$(basename "$script_path")}"

  if is_dry_run; then
    dry_run_ui_info "Would execute script: $description"
    dry_run_ui_info "  Script path: $script_path"
    return 0
  else
    return 1  # Indicates that actual execution should proceed
  fi
}
