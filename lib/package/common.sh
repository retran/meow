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
    verbose_action_msg "Caching $manager package list..."
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
  local component="$1"
  local manager_name="$2"
  local install_cmd="$3"
  local check_cmd="$4"

  # Create display name for the package manager
  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="homebrew" ;;
    "npm") manager_display_name="npm" ;;
    "pipx") manager_display_name="pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="App Store" ;;
    "go") manager_display_name="go" ;;
    "apt") manager_display_name="apt" ;;
    "pacman") manager_display_name="pacman" ;;
    "apk") manager_display_name="apk" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  [[ ! -f "$package_file" ]] && {
    return 0
  }

  # Count packages first
  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue
    ((total_packages++)) || true
  done <"$package_file"

  if [[ $total_packages -eq 0 ]]; then
    return 0
  fi

  local installed_count=0 already_installed_count=0 failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      verbose_success_tick_msg "$package_name (already installed)"
      ((already_installed_count++)) || true
    else
      if [[ "$MEOW_VERBOSE" == "true" ]]; then
        run_package_operation "$package_name" \
          "install" \
          "Installing $package_name" \
          "Successfully installed $package_name" \
          "Failed to install $package_name" \
          "" \
          $install_cmd "$package_name"
        if [[ $? -eq 0 ]]; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        # In non-verbose mode, show silent spinner that disappears after completion
        if ui_silent_spinner "[$manager_display_name] Installing $package_name..." $install_cmd "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
          # Only show errors in non-verbose mode
          error_msg "Failed to install $package_name"
        fi
      fi
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))

  # Compact summary
  if ((failed_count == 0)); then
    if ((installed_count > 0)); then
      indent_msg "$(capitalize "$manager_name"): ✓ $installed_count installed, $already_installed_count already present"
    else
      indent_msg "$(capitalize "$manager_name"): ✓ $already_installed_count/$total_packages already present"
    fi
    return 0
  else
    indent_msg "$(capitalize "$manager_name"): ✗ $failed_count failed, $installed_count installed, $already_installed_count already present"
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
  local component="$1"
  local manager_name="$2"
  local update_cmd="$3"
  local check_cmd="$4"
  local skip_pattern="${5:-}"

  # Create display name for the package manager
  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="Homebrew" ;;
    "npm") manager_display_name="NPM" ;;
    "pipx") manager_display_name="Pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="Mac App Store" ;;
    "go") manager_display_name="Go" ;;
    "apt") manager_display_name="APT" ;;
    "pacman") manager_display_name="Pacman" ;;
    "apk") manager_display_name="APK" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  [[ ! -f "$package_file" ]] && {
    # Тихо возвращаемся, если файла пакетов нет (это нормально)
    return 0
  }

  # Count packages first
  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue
    if eval "$check_cmd \"$package_name\""; then
      ((total_packages++)) || true
    fi
  done <"$package_file"

  if [[ $total_packages -eq 0 ]]; then
    return 0
  fi

  local updated_count=0 up_to_date_count=0 failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      # Check if package is up-to-date using skip pattern
      local is_up_to_date=false
      if [[ -n "$skip_pattern" ]]; then
        local test_output
        if [[ "$MEOW_VERBOSE" == "true" ]]; then
          # In verbose mode, show what we're checking
          verbose_info "Checking if $package_name is up-to-date..."
          test_output=$(eval "$update_cmd $package_name" 2>&1) || true
        else
          # In non-verbose mode, show silent spinner for the check
          local temp_file
          temp_file=$(mktemp)
          if ui_silent_spinner "[$manager_display_name] Checking $package_name..." bash -c "$update_cmd $package_name >$temp_file 2>&1"; then
            test_output=$(cat "$temp_file")
          else
            test_output=$(cat "$temp_file")
          fi
          rm -f "$temp_file"
        fi
        if grep -Eq "$skip_pattern" <<<"$test_output"; then
          is_up_to_date=true
        fi
      fi

      if [[ "$is_up_to_date" == "true" ]]; then
        verbose_success_tick_msg "$package_name (up-to-date)"
        ((up_to_date_count++)) || true
      else
        if [[ "$MEOW_VERBOSE" == "true" ]]; then
          run_package_operation "$package_name" \
            "update" \
            "Updating $package_name" \
            "Successfully updated $package_name" \
            "Failed to update $package_name" \
            "" \
            $update_cmd "$package_name"
          if [[ $? -eq 0 ]]; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
          fi
        else
          # In non-verbose mode, show silent spinner that disappears after completion
          if ui_silent_spinner "[$manager_display_name] Updating $package_name..." $update_cmd "$package_name"; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
            # Only show errors in non-verbose mode
            error_msg "Failed to update $package_name"
          fi
        fi
      fi
    else
      warning_msg "$package_name (not installed, skipping)"
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((updated_count > 0)); then
      indent_msg "$(capitalize "$manager_name"): ✓ $updated_count updated, $up_to_date_count up-to-date"
      return 0
    else
      indent_msg "$(capitalize "$manager_name"): ✓ $up_to_date_count/$total_packages up-to-date"
      return 0
    fi
  else
    indent_msg "$(capitalize "$manager_name"): ✗ $failed_count failed, $updated_count updated, $up_to_date_count up-to-date"
    return 1
  fi
}

uninstall_packages_generic() {
  local component="$1"
  local manager_name="$2"
  local uninstall_cmd="$3"
  local check_cmd="$4"

  # Create display name for the package manager
  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="Homebrew" ;;
    "npm") manager_display_name="NPM" ;;
    "pipx") manager_display_name="Pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="Mac App Store" ;;
    "go") manager_display_name="Go" ;;
    "apt") manager_display_name="APT" ;;
    "pacman") manager_display_name="Pacman" ;;
    "apk") manager_display_name="APK" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  # Show header only in verbose mode
  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    step_header "$manager_display_name Package Removal ($component)"
  fi

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  [[ ! -f "$package_file" ]] && {
    # Тихо возвращаемся, если файла пакетов нет (это нормально)
    return 0
  }

  local uninstalled_count=0 not_installed_count=0 failed_count=0
  local start_time
  start_time=$(date +%s)

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    [[ -z "$package_name" ]] && continue

    if eval "$check_cmd \"$package_name\""; then
      if [[ "$MEOW_VERBOSE" == "true" ]]; then
        run_package_operation "$package_name" \
          "uninstall" \
          "Uninstalling $package_name" \
          "Successfully uninstalled $package_name" \
          "Failed to uninstall $package_name" \
          "" \
          $uninstall_cmd "$package_name"
        if [[ $? -eq 0 ]]; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        # In non-verbose mode, show silent spinner that disappears after completion
        if ui_silent_spinner "[$manager_display_name] Uninstalling $package_name..." $uninstall_cmd "$package_name"; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
          # Only show errors in non-verbose mode
          error_msg "Failed to uninstall $package_name"
        fi
      fi
    else
      verbose_info "$package_name (not installed, skipping)"
      ((not_installed_count++)) || true
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))

  # Compact summary
  if ((failed_count == 0)); then
    if ((uninstalled_count > 0)); then
      indent_msg "$(capitalize "$manager_name"): ✓ $uninstalled_count uninstalled, $not_installed_count not installed"
    else
      indent_msg "$(capitalize "$manager_name"): ✓ $not_installed_count/$((uninstalled_count + not_installed_count)) not installed"
    fi
    return 0
  else
    indent_msg "$(capitalize "$manager_name"): ✗ $failed_count failed, $uninstalled_count uninstalled, $not_installed_count not installed"
    return 1
  fi
}
