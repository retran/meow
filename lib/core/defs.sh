#!/usr/bin/env bash

if [ -n "${_LIB_DEFS_SOURCED:-}" ]; then
  return 0
fi
_LIB_DEFS_SOURCED=1

readonly MEOW_PRESETS_DIR="${MEOW}/presets"
readonly MEOW_INSTALLED_PRESETS_DIR="${MEOW}/.installed/presets"

readonly MEOW_COMPONENTS_DIR="${MEOW}/components"
readonly MEOW_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components"
readonly MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="${MEOW}/.installed/components-manual"

readonly MEOW_DOWNLOADS_DIR="${MEOW}/.downloads"

_MEOW_DIRS_TO_CREATE=(
  "${MEOW_INSTALLED_PRESETS_DIR}"
  "${MEOW_INSTALLED_COMPONENTS_DIR}"
  "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}"
  "${MEOW_DOWNLOADS_DIR}"
)

_first_dir_check=true
for _dir in "${_MEOW_DIRS_TO_CREATE[@]}"; do
  if [ -z "${_dir}" ]; then
    continue
  fi

  if [ ! -d "${_dir}" ]; then
    if [ "${_first_dir_check}" = "true" ] && [ "${MEOW_VERBOSE:-}" = "true" ]; then
      ui_verbose_info "Ensuring core state directories exist..."
      _first_dir_check=false
    fi

    ui_verbose_info "State directory missing, preparing to create: ${_dir}"
    if ! dry_run_file_operation "create_dir" "${_dir}"; then
      if mkdir -p "${_dir}"; then
        ui_action_success "Created state directory: ${_dir}"
      else
        ui_action_error "Failed to create state directory: ${_dir}"
      fi
    fi
  fi
done

unset _dir _MEOW_DIRS_TO_CREATE _first_dir_check
