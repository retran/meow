#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_CORE_BASH_COMPAT_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_BASH_COMPAT_SOURCED=1

if [[ -n "${MEOW:-}" ]]; then
  source "$MEOW/lib/strings/strings.sh"
fi

get_bash_version_number() {
  local version="${BASH_VERSION%%[^0-9.]*}"
  local major="${version%%.*}"
  local minor="${version#*.}"
  minor="${minor%%.*}"

  major="${major:-0}"
  minor="${minor:-0}"

  echo "$((major * 100 + minor))"
}

check_bash_version() {
  local required_major="${1:-3}"
  local required_minor="${2:-2}"
  local required_version=$((required_major * 100 + required_minor))
  local current_version

  current_version=$(get_bash_version_number)

  [[ $current_version -ge $required_version ]]
}

show_bash_version_info() {
  local current_version

  current_version=$(get_bash_version_number)

  if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
    ui_info "$(fmt "bash_version_info" "${BASH_VERSION}" "$current_version")"

    if check_bash_version 4 0; then
      ui_success "$(fmt "bash_modern_features_available")"
    else
      ui_warning "$(fmt "bash_using_compatibility_mode")"
    fi
  else
    echo "$(fmt "bash_version_info" "${BASH_VERSION}" "$current_version")"
  fi
}

warn_bash_compatibility() {
  if ! check_bash_version 4 0; then
    if [[ -n "${_LIB_CORE_UI_SOURCED:-}" ]]; then
      ui_info_detail "$(fmt "bash_3_2_compatibility_mode")"
      ui_info "$(fmt "bash_upgrade_recommendation")"
    else
      echo "$(fmt "bash_3_2_compatibility_mode")"
      echo "$(fmt "bash_upgrade_recommendation")"
    fi
  fi
}
