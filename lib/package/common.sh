#!/usr/bin/env bash

if [ -n "${_LIB_PACKAGE_COMMON_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_COMMON_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/dry_run.sh"

dry_run_package_operation() {
  local manager_display_name="$1"
  local operation="$2"
  local package_name="$3"
  dry_run_log "$(_f "Would %s %s package %s" "$operation" "$manager_display_name" "$package_name")"
}

run_package_operation() {
  local start_msg="$1"
  local success_msg="$2"
  local failure_msg="$3"
  shift 3
  local cmd_and_args=("$@")

  ui_verbose_action_start "$start_msg"

  if "${cmd_and_args[@]}"; then
    ui_verbose_action_success "$success_msg"
    return 0
  else
    ui_verbose_action_error "$failure_msg"
    return 1
  fi
}

cache_package_list() {
  local manager="$1"
  local list_command="$2"

  local cache_var="_$(echo "$manager" | tr '[:lower:]' '[:upper:]')_INSTALLED_PACKAGES"

  if [ -z "${!cache_var:-}" ]; then
    ui_verbose_action_start "$(_f "Caching installed %s packages..." "$manager")"
    # shellcheck disable=SC2296 # indirect assignment with eval is necessary for Bash 3.2
    eval "$cache_var=\"$(eval "$list_command")\""
    ui_verbose_action_success "$(_f "Successfully cached %s packages." "$manager")"
  fi
}

is_package_installed() {
  local manager="$1"
  local package="$2"

  local cache_var="_$(echo "$manager" | tr '[:lower:]' '[:upper:]')_INSTALLED_PACKAGES"

  grep -qE "^$package$" <<<"${!cache_var}"
}

parse_package_line() {
  local line="$1"

  case "$line" in
    '#'*) return ;;
  esac

  if [ -z "$(echo "$line" | tr -d ' ')" ]; then
    return
  fi

  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  echo "$line"
}

capitalize() {
  local str="$1"
  local first_char rest
  first_char=$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')
  rest="${str:1}"
  echo "${first_char}${rest}"
}

install_packages_generic() {
  local component="$1"
  local manager_name="$2"
  local install_cmd="$3"
  local check_cmd="$4"

  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="Homebrew" ;;
    "npm") manager_display_name="NPM" ;;
    "pipx") manager_display_name="Pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="App Store" ;;
    "go") manager_display_name="Go" ;;
    "apt") manager_display_name="APT" ;;
    "pacman") manager_display_name="Pacman" ;;
    "apk") manager_display_name="APK" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  if [ ! -f "$package_file" ]; then
    return 0
  fi

  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -n "$package_name" ]; then
      ((total_packages++)) || true
    fi
  done <"$package_file"

  if [ "$total_packages" -eq 0 ]; then
    return 0
  fi

  local installed_count=0 already_installed_count=0 failed_count=0

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi

    if eval "$check_cmd \"$package_name\""; then
      ui_verbose_action_success "$(_f "%s %s is already installed." "$manager_display_name" "$package_name")"
      ((already_installed_count++)) || true
    else
      if is_dry_run; then
        dry_run_package_operation "$manager_display_name" "install" "$package_name"
        ((installed_count++)) || true
        continue
      fi

      if [ "$MEOW_VERBOSE" = "true" ]; then
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by run_package_operation's design
        if run_package_operation \
          "$(_f "Installing %s %s..." "$manager_display_name" "$package_name")" \
          "$(_f "Successfully installed %s %s." "$manager_display_name" "$package_name")" \
          "$(_f "Failed to install %s %s!" "$manager_display_name" "$package_name")" \
          $install_cmd "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by ui_silent_spinner's design
        if ui_silent_spinner "$(_f "Installing %s %s" "$manager_display_name" "$package_name")" $install_cmd "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
          ui_action_error "$(_f "Failed to install %s %s!" "$manager_display_name" "$package_name")"
        fi
      fi
    fi
  done <"$package_file"

  if ((failed_count == 0)); then
    if ((installed_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d installed, %d already present" "$(capitalize "$manager_name")" "$installed_count" "$already_installed_count")"
    else
      ui_indent "$(_f "%s: ✓ All %d packages already present" "$(capitalize "$manager_name")" "$already_installed_count")"
    fi
    return 0
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d installed, %d already present" "$(capitalize "$manager_name")" "$failed_count" "$installed_count" "$already_installed_count")"
    return 1
  fi
}

update_packages_generic() {
  local component="$1"
  local manager_name="$2"
  local update_cmd="$3"
  local check_cmd="$4"
  local skip_pattern="${5:-}"

  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="Homebrew" ;;
    "npm") manager_display_name="NPM" ;;
    "pipx") manager_display_name="Pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="App Store" ;;
    "go") manager_display_name="Go" ;;
    "apt") manager_display_name="APT" ;;
    "pacman") manager_display_name="Pacman" ;;
    "apk") manager_display_name="APK" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  if [ ! -f "$package_file" ]; then
    return 0
  fi

  local total_packages=0
  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi
    if eval "$check_cmd \"$package_name\""; then
      ((total_packages++)) || true
    fi
  done <"$package_file"

  if [ "$total_packages" -eq 0 ]; then
    return 0
  fi

  local updated_count=0 up_to_date_count=0 failed_count=0

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi

    if eval "$check_cmd \"$package_name\""; then
      local is_up_to_date=false
      if [ -n "$skip_pattern" ]; then
        local test_output
        if [ "$MEOW_VERBOSE" = "true" ]; then
          ui_verbose_info "$(_f "Checking if %s %s is up-to-date..." "$manager_display_name" "$package_name")"
          test_output=$(eval "$update_cmd \"$package_name\"" 2>&1) || true
        else
          local temp_file
          temp_file=$(mktemp) || {
            ui_action_error "$(_f "Failed to create temporary file for update check.")"
            return 1
          }

          # shellcheck disable=SC2086 # Arguments are intentionally word-split by ui_silent_spinner's design
          if ui_silent_spinner "$(_f "Checking %s %s" "$manager_display_name" "$package_name")" bash -c "eval \"$update_cmd \\\"$package_name\\\"\" >\"$temp_file\" 2>&1"; then
            test_output=$(cat "$temp_file")
          else
            test_output=$(cat "$temp_file")
            ui_action_error "$(_f "Failed to check update status for %s %s. Output:\n%s" "$manager_display_name" "$package_name" "$test_output")"
          fi
          rm -f "$temp_file" || true
        fi
        if echo "$test_output" | grep -Eq "$skip_pattern"; then
          is_up_to_date=true
        fi
      fi

      if [ "$is_up_to_date" = "true" ]; then
        ui_verbose_action_success "$(_f "%s %s is already up-to-date." "$manager_display_name" "$package_name")"
        ((up_to_date_count++)) || true
      else
        if is_dry_run; then
          dry_run_package_operation "$manager_display_name" "update" "$package_name"
          ((updated_count++)) || true
          continue
        fi

        if [ "$MEOW_VERBOSE" = "true" ]; then
          # shellcheck disable=SC2086 # Arguments are intentionally word-split by run_package_operation's design
          if run_package_operation \
            "$(_f "Updating %s %s..." "$manager_display_name" "$package_name")" \
            "$(_f "Successfully updated %s %s." "$manager_display_name" "$package_name")" \
            "$(_f "Failed to update %s %s!" "$manager_display_name" "$package_name")" \
            $update_cmd "$package_name"; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
          fi
        else
          # shellcheck disable=SC2086 # Arguments are intentionally word-split by ui_silent_spinner's design
          if ui_silent_spinner "$(_f "Updating %s %s" "$manager_display_name" "$package_name")" $update_cmd "$package_name"; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
            ui_action_error "$(_f "Failed to update %s %s!" "$manager_display_name" "$package_name")"
          fi
        fi
      fi
    else
      ui_action_warning "$(_f "Package %s %s not installed, skipping update." "$manager_display_name" "$package_name")"
    fi
  done <"$package_file"

  if ((failed_count == 0)); then
    if ((updated_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d updated, %d up-to-date" "$(capitalize "$manager_name")" "$updated_count" "$up_to_date_count")"
      return 0
    else
      ui_indent "$(_f "%s: ✓ All %d packages up-to-date" "$(capitalize "$manager_name")" "$up_to_date_count")"
      return 0
    fi
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d updated, %d up-to-date" "$(capitalize "$manager_name")" "$failed_count" "$updated_count" "$up_to_date_count")"
    return 1
  fi
}

uninstall_packages_generic() {
  local component="$1"
  local manager_name="$2"
  local uninstall_cmd="$3"
  local check_cmd="$4"

  local manager_display_name
  case "$manager_name" in
    "homebrew") manager_display_name="Homebrew" ;;
    "npm") manager_display_name="NPM" ;;
    "pipx") manager_display_name="Pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="App Store" ;;
    "go") manager_display_name="Go" ;;
    "apt") manager_display_name="APT" ;;
    "pacman") manager_display_name="Pacman" ;;
    "apk") manager_display_name="APK" ;;
    *) manager_display_name="$(capitalize "$manager_name")" ;;
  esac

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  if [ ! -f "$package_file" ]; then
    return 0
  fi

  local uninstalled_count=0 not_installed_count=0 failed_count=0

  while IFS= read -r line; do
    local package_name
    package_name=$(parse_package_line "$line")
    if [ -z "$package_name" ]; then
      continue
    fi

    if eval "$check_cmd \"$package_name\""; then
      if is_dry_run; then
        dry_run_package_operation "$manager_display_name" "remove" "$package_name"
        ((uninstalled_count++)) || true
        continue
      fi

      if [ "$MEOW_VERBOSE" = "true" ]; then
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by run_package_operation's design
        if run_package_operation \
          "$(_f "Uninstalling %s %s..." "$manager_display_name" "$package_name")" \
          "$(_f "Successfully uninstalled %s %s." "$manager_display_name" "$package_name")" \
          "$(_f "Failed to uninstall %s %s!" "$manager_display_name" "$package_name")" \
          $uninstall_cmd "$package_name"; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        # shellcheck disable=SC2086 # Arguments are intentionally word-split by ui_silent_spinner's design
        if ui_silent_spinner "$(_f "Uninstalling %s %s" "$manager_display_name" "$package_name")" $uninstall_cmd "$package_name"; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
          ui_action_error "$(_f "Failed to uninstall %s %s!" "$manager_display_name" "$package_name")"
        fi
      fi
    else
      ui_verbose_info "$(_f "Package %s %s not installed, skipping uninstallation." "$manager_display_name" "$package_name")"
      ((not_installed_count++)) || true
    fi
  done <"$package_file"

  if ((failed_count == 0)); then
    if ((uninstalled_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d uninstalled, %d not installed" "$(capitalize "$manager_name")" "$uninstalled_count" "$not_installed_count")"
    else
      ui_indent "$(_f "%s: ✓ All %d packages already not installed" "$(capitalize "$manager_name")" "$not_installed_count")"
    fi
    return 0
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d uninstalled, %d not installed" "$(capitalize "$manager_name")" "$failed_count" "$uninstalled_count" "$not_installed_count")"
    return 1
  fi
}
