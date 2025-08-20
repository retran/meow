#!/usr/bin/env bash

if [[ -n "${_LIB_PACKAGE_COMMON_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_COMMON_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"

cache_package_list() {
  local manager="$1"
  local cache_var="_${manager^^}_INSTALLED_PACKAGES"
  local list_command="$2"

  if [[ -z "${!cache_var:-}" ]]; then
    action_msg "Caching $manager package list..."
    eval "$cache_var=\"$(eval "$list_command")\""
  fi
}

is_package_installed() {
  local manager="$1"
  local package="$2"
  local cache_var="_${manager^^}_INSTALLED_PACKAGES"

  grep -qE "^$package$" <<<"${!cache_var}"
}

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

install_packages_generic() {
  local category="$1"
  local manager_name="$2"
  local install_cmd="$3"
  local check_cmd="$4"

  local package_dir_var package_dir
  package_dir_var="$(echo "$manager_name" | tr '[:lower:]' '[:upper:]')_PACKAGES_DIR"
  package_dir="${!package_dir_var}"

  step_header "$(capitalize "$manager_name") Packages ($category)"

  local package_file="${package_dir}/${category}.list"
  [[ ! -f "$package_file" ]] && {
    error_msg "Package list not found: $package_file"
    return 1
  }

  local installed_count=0 already_installed_count=0 failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      success_tick_msg "$package_name (already installed)"
      ((already_installed_count++)) || true
    else
      run_package_operation "$package_name" \
        "install" \
        "Installing $package_name" \
        "Successfully installed $package_name" \
        "Failed to install $package_name" \
        "" \
        "$install_cmd" "$package_name"
      if [[ $? -eq 0 ]]; then
        ((installed_count++)) || true
      else
        ((failed_count++)) || true
      fi
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((installed_count > 0)); then
      success_tick_msg "Installed $installed_count packages ($already_installed_count already present) (${duration}s)"
    else
      success_tick_msg "All packages already present ($already_installed_count) (${duration}s)"
    fi
    return 0
  else
    warning "Completed with $failed_count error(s) (${duration}s)"
    return 1
  fi
}

capitalize() {
  local str="$1"
  local first_char rest
  first_char=$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')
  rest="${str:1}"
  echo "${first_char}${rest}"
}

update_packages_generic() {
  local category="$1"
  local manager_name="$2"
  local update_cmd="$3"
  local check_cmd="$4"
  local skip_pattern="${5:-}"

  local package_dir_var package_dir
  package_dir_var="$(echo "$manager_name" | tr '[:lower:]' '[:upper:]')_PACKAGES_DIR"
  package_dir="${!package_dir_var}"

  step_header "$(capitalize "$manager_name") Updates ($category)"

  local package_file="${package_dir}/${category}.list"
  [[ ! -f "$package_file" ]] && {
    error_msg "Package list not found: $package_file"
    return 1
  }

  local updated_count=0 up_to_date_count=0 failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      if [[ -n "$skip_pattern" ]] && eval "$update_cmd $package_name" 2>&1 | grep -Eq "$skip_pattern"; then
        success_tick_msg "$package_name (up-to-date)"
        ((up_to_date_count++)) || true
      else
        run_package_operation "$package_name" \
          "update" \
          "Updating $package_name" \
          "Successfully updated $package_name" \
          "Failed to update $package_name" \
          "" \
          "$update_cmd" "$package_name"
        if [[ $? -eq 0 ]]; then
          ((updated_count++)) || true
        else
          ((failed_count++)) || true
        fi
      fi
    else
      warning "$package_name (not installed, skipping)"
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((updated_count > 0)); then
      success_tick_msg "Updated $updated_count packages ($up_to_date_count up-to-date) (${duration}s)"
      return 0
    else
      success_tick_msg "All packages up-to-date ($up_to_date_count) (${duration}s)"
      return 0
    fi
  else
    error_msg "Failed to update $failed_count packages (${duration}s)"
    return 1
  fi
}
