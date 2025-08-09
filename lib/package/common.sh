#!/usr/bin/env bash

# lib/package/common.sh - Common package manager functions

if [[ -n "${_LIB_PACKAGE_COMMON_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_COMMON_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"

parse_package_line() {
  local line="$1"
  [[ $line == \#* ]] && return
  [[ -z "${line// /}" ]] && return

  line="${line%%#*}"
  line="${line%%;*}"

  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  echo "$line"
}

run_package_operation() {
  # $1 = indent, $2 = package name, $3 = action (install/update),
  # $4 = start msg, $5 = success msg, $6 = fail msg, $7 = unchanged msg,
  # remaining args = command + its arguments
  local indent="$1"
  local pkg="$2"
  local action="$3"
  local start_msg="$4"
  local success_msg="$5"
  local fail_msg="$6"
  local unchanged_msg="$7"
  shift 7
  local cmd_args=("$@")

  ui_spinner "$indent" "$start_msg" \
    --success "$success_msg" \
    --fail "$fail_msg" \
    "${cmd_args[@]}"
}

install_packages_generic() {
  local category="$1"
  local indent_level="${2:-1}"
  local manager_name="$3"
  local install_cmd="$4"
  local check_cmd="$5"

  local package_dir_var="$(echo "$manager_name" | tr '[:lower:]' '[:upper:]')_PACKAGES_DIR"
  local package_dir="${!package_dir_var}"

  step_header "$indent_level" "${manager_name^} Packages ($category)"

  local package_file="${package_dir}/${category}.list"
  [[ ! -f "$package_file" ]] && {
    indented_error_msg "$indent_level" "Package list not found: $package_file"
    return 1
  }

  local installed_count=0
  local already_installed_count=0
  local failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      success_tick_msg "$((indent_level + 1))" "$package_name (already installed)"
      ((already_installed_count++))
    else
      run_package_operation "$((indent_level + 1))" "$package_name" "install" \
        "Installing $package_name" \
        "Successfully installed $package_name" \
        "Failed to install $package_name" \
        "" \
        $install_cmd "$package_name"
      if [[ $? -eq 0 ]]; then
        ((installed_count++))
      else
        ((failed_count++))
      fi
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((installed_count > 0)); then
      success_tick_msg "$indent_level" "Installed $installed_count packages ($already_installed_count already present) (${duration}s)"
    else
      success_tick_msg "$indent_level" "All packages already present ($already_installed_count) (${duration}s)"
    fi
    return 0
  else
    indented_warning "$indent_level" "Completed with $failed_count error(s) (${duration}s)"
    return 1
  fi
}

update_packages_generic() {
  local category="$1"
  local indent_level="${2:-1}"
  local manager_name="$3"
  local update_cmd="$4"
  local check_cmd="$5"
  local skip_pattern="${6:-}"

  local package_dir_var="${manager_name^^}_PACKAGES_DIR"
  local package_dir="${!package_dir_var}"

  step_header "$indent_level" "${manager_name^} Updates ($category)"

  local package_file="${package_dir}/${category}.list"
  [[ ! -f "$package_file" ]] && {
    indented_error_msg "$indent_level" "Package list not found: $package_file"
    return 1
  }

  local updated_count=0
  local up_to_date_count=0
  local failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      if [[ -n "$skip_pattern" ]] && eval "$update_cmd $package_name" 2>&1 | grep -Eq "$skip_pattern"; then
        success_tick_msg "$((indent_level + 1))" "$package_name (up-to-date)"
        ((up_to_date_count++))
      else
        run_package_operation "$((indent_level + 1))" "$package_name" "update" \
          "Updating $package_name" \
          "Successfully updated $package_name" \
          "Failed to update $package_name" \
          "" \
          $update_cmd "$package_name"
        if [[ $? -eq 0 ]]; then
          ((updated_count++))
        else
          ((failed_count++))
        fi
      fi
    else
      indented_warning "$((indent_level + 1))" "$package_name (not installed, skipping)"
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((updated_count > 0)); then
      success_tick_msg "$indent_level" "Updated $updated_count packages ($up_to_date_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "$indent_level" "All packages up-to-date ($up_to_date_count) (${duration}s)"
      return 100
    fi
  else
    indented_error_msg "$indent_level" "Failed to update $failed_count packages (${duration}s)"
    return 1
  fi
}
