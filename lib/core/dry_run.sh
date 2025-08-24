#!/usr/bin/env bash

if [[ -n "${_LIB_CORE_DRY_RUN_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_DRY_RUN_SOURCED=1

# TODO looks broken

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/colors.sh"

is_dry_run() {
  [[ "${MEOW_DRY_RUN:-}" == "true" ]]
}

dry_run_command() {
  local description="$1"
  shift

  if is_dry_run; then
    dry_run_ui_info "$(fmt "dry_run_would_execute" "$description")"
    return 0
  else
    "$@"
  fi
}

dry_run_info() {
  local message="$1"
  echo -e "  ${CYAN}$(fmt "dry_run_prefix")${RESET} $message"
}

dry_run_ui_info() {
  dry_run_info "$@"
}

dry_run_command_info() {
  local command="$1"
  echo -e "  ${CYAN}$(fmt "dry_run_prefix")${RESET}   $(fmt "dry_run_command" "${NORMAL}$command${RESET}")"
}

dry_run_file_operation() {
  local operation="$1"
  local target="$2"
  local source="${3:-}"

  if is_dry_run; then
    case "$operation" in
      "create_symlink")
        dry_run_ui_info "$(fmt "dry_run_create_symlink" "$target" "$source")"
        ;;
      "create_dir")
        dry_run_ui_info "$(fmt "dry_run_create_directory" "$target")"
        ;;
      "remove_file")
        dry_run_ui_info "$(fmt "dry_run_remove_file" "$target")"
        ;;
      "remove_dir")
        dry_run_ui_info "$(fmt "dry_run_remove_directory" "$target")"
        ;;
      "backup_file")
        dry_run_ui_info "$(fmt "dry_run_backup_file" "$target")"
        ;;
      "restore_file")
        dry_run_ui_info "$(fmt "dry_run_restore_file" "$target" "$source")"
        ;;
      *)
        dry_run_ui_info "$(fmt "dry_run_file_operation" "$operation" "$target")"
        ;;
    esac
    return 0
  else
    return 1
  fi
}

dry_run_package_operation() {
  local manager="$1"
  local operation="$2"
  local packages="$3"

  if is_dry_run; then
    case "$operation" in
      "install")
        dry_run_ui_info "$(fmt "dry_run_install_packages" "$manager" "$packages")"
        ;;
      "update")
        dry_run_ui_info "$(fmt "dry_run_update_packages" "$manager" "$packages")"
        ;;
      "remove")
        dry_run_ui_info "$(fmt "dry_run_remove_packages" "$manager" "$packages")"
        ;;
      *)
        dry_run_ui_info "$(fmt "dry_run_perform_operation" "$manager" "$operation" "$packages")"
        ;;
    esac
    return 0
  else
    return 1
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
        dry_run_ui_info "$(fmt "dry_run_clone_repository" "$repo_path")"
        if [[ -n "$details" ]]; then
          dry_run_ui_info "  $(fmt "dry_run_repository_url" "$details")"
        fi
        ;;
      "pull")
        dry_run_ui_info "$(fmt "dry_run_pull_updates" "$repo_path")"
        ;;
      "checkout")
        dry_run_ui_info "$(fmt "dry_run_checkout" "$details" "$repo_path")"
        ;;
      *)
        dry_run_ui_info "$(fmt "dry_run_git_operation" "$operation" "$repo_path")"
        ;;
    esac
    return 0
  else
    return 1
  fi
}

# Wrapper for script execution in dry-run mode
dry_run_script_execution() {
  local script_path="$1"
  local description="${2:-$(basename "$script_path")}"

  if is_dry_run; then
    dry_run_ui_info "$(fmt "dry_run_execute_script" "$description")"
    dry_run_ui_info "$(fmt "dry_run_script_path" "$script_path")"
    return 0
  else
    return 1
  fi
}
