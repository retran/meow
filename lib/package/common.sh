#!/usr/bin/env bash

# Helper function for safe string formatting, injected by the inliner script.
_f() {
  local template="$1"
  shift
  printf -- "$template" "$@"
}

if [[ -n "${_LIB_PACKAGE_COMMON_SOURCED:-}" ]]; then
  return 0
fi
_LIB_PACKAGE_COMMON_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/dry_run.sh"

cache_package_list() {
  local manager="$1"
  local cache_var="_${manager^^}_INSTALLED_PACKAGES"
  local list_command="$2"

  if [[ -z "${!cache_var:-}" ]]; then
    ui_verbose_action_start "$(_f "TODO: write message - caching_package_list" "$manager")"
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
      ui_verbose_action_success "$(_f "Package already installed: %s" "$package_name")"
      ((already_installed_count++)) || true
    else
      if is_dry_run; then
        dry_run_package_operation "$manager_name" "install" "$package_name"
        ((installed_count++)) || true
        continue
      fi

      if [[ "$MEOW_VERBOSE" == "true" ]]; then
        run_package_operation "$package_name" \
          "install" \
          "$(_f "Installing %s" "$package_name")" \
          "$(_f "Successfully installed %s" "$package_name")" \
          "$(_f "Failed to install %s" "$package_name")" \
          "" \
          $install_cmd "$package_name"
        if [[ $? -eq 0 ]]; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        if ui_silent_spinner "$(_f "Installing %s %s" "$manager_display_name" "$package_name")" $install_cmd "$package_name"; then
          ((installed_count++)) || true
        else
          ((failed_count++)) || true
          ui_action_error "$(_f "Failed to install %s" "$package_name")"
        fi
      fi
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))

  if ((failed_count == 0)); then
    if ((installed_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d installed, %d already present" "$(capitalize "$manager_name")" "$installed_count" "$already_installed_count")"
    else
      ui_indent "$(_f "%s: ✓ %d/%d already present" "$(capitalize "$manager_name")" "$already_installed_count" "$total_packages")"
    fi
    return 0
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d installed, %d already present" "$(capitalize "$manager_name")" "$failed_count" "$installed_count" "$already_installed_count")"
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
  [[ ! -f "$package_file" ]] && {
    return 0
  }

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
      local is_up_to_date=false
      if [[ -n "$skip_pattern" ]]; then
        local test_output
        if [[ "$MEOW_VERBOSE" == "true" ]]; then
          ui_verbose_info "$(_f "TODO: write message - checking_package_up_to_date" "$package_name")"
          test_output=$(eval "$update_cmd $package_name" 2>&1) || true
        else
          local temp_file
          temp_file=$(mktemp)
          if ui_silent_spinner "$(_f "Checking %s %s" "$manager_display_name" "$package_name")" bash -c "$update_cmd $package_name >$temp_file 2>&1"; then
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
        ui_verbose_action_success "$(_f "TODO: write message - package_up_to_date" "$package_name")"
        ((up_to_date_count++)) || true
      else
        if is_dry_run; then
          dry_run_package_operation "$manager_name" "update" "$package_name"
          ((updated_count++)) || true
          continue
        fi

        if [[ "$MEOW_VERBOSE" == "true" ]]; then
          run_package_operation "$package_name" \
            "update" \
            "$(_f "Updating %s" "$package_name")" \
            "$(_f "Successfully updated %s" "$package_name")" \
            "$(_f "Failed to update %s" "$package_name")" \
            "" \
            $update_cmd "$package_name"
          if [[ $? -eq 0 ]]; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
          fi
        else
          if ui_silent_spinner "$(_f "Updating %s %s" "$manager_display_name" "$package_name")" $update_cmd "$package_name"; then
            ((updated_count++)) || true
          else
            ((failed_count++)) || true
            ui_action_error "$(_f "Failed to update %s" "$package_name")"
          fi
        fi
      fi
    else
      ui_action_warning "$(_f "Package not installed, skipping: %s" "$package_name")"
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))
  if ((failed_count == 0)); then
    if ((updated_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d updated, %d up-to-date" "$(capitalize "$manager_name")" "$updated_count" "$up_to_date_count")"
      return 0
    else
      ui_indent "$(_f "%s: ✓ %d/%d up-to-date" "$(capitalize "$manager_name")" "$up_to_date_count" "$total_packages")"
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
    "homebrew") manager_display_name="homebrew" ;;
    "npm") manager_display_name="npm" ;;
    "pipx") manager_display_name="pipx" ;;
    "vscode") manager_display_name="VS Code" ;;
    "mas") manager_display_name="App Store" ;;
    "go") manager_display_name="go" ;;
    "apt") manager_display_name="apt" ;;
    "pacman") manager_display_name="pacman" ;;
    "apk") manager_display_name="apk" ;;
    *) manager_display_name="$manager_name" ;;
  esac

  if [[ "$MEOW_VERBOSE" == "true" ]]; then
    ui_step_header "$manager_display_name Package Removal ($component)"
  fi

  local package_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${manager_name}.list"
  [[ ! -f "$package_file" ]] && {
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
      if is_dry_run; then
        dry_run_package_operation "$manager_name" "remove" "$package_name"
        ((uninstalled_count++)) || true
        continue
      fi

      if [[ "$MEOW_VERBOSE" == "true" ]]; then
        run_package_operation "$package_name" \
          "uninstall" \
          "$(_f "Uninstalling %s" "$package_name")" \
          "$(_f "Successfully uninstalled %s" "$package_name")" \
          "$(_f "Failed to uninstall %s" "$package_name")" \
          "" \
          $uninstall_cmd "$package_name"
        if [[ $? -eq 0 ]]; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
        fi
      else
        if ui_silent_spinner "$(_f "Uninstalling %s %s" "$manager_display_name" "$package_name")" $uninstall_cmd "$package_name"; then
          ((uninstalled_count++)) || true
        else
          ((failed_count++)) || true
          ui_action_error "$(_f "Failed to uninstall %s" "$package_name")"
        fi
      fi
    else
      ui_verbose_info "$(_f "Package not installed, skipping: %s" "$package_name")"
      ((not_installed_count++)) || true
    fi
  done <"$package_file"

  local duration=$(($(date +%s) - start_time))

  if ((failed_count == 0)); then
    if ((uninstalled_count > 0)); then
      ui_indent "$(_f "%s: ✓ %d uninstalled, %d not installed" "$(capitalize "$manager_name")" "$uninstalled_count" "$not_installed_count")"
    else
      ui_indent "$(_f "%s: ✓ %d/%d not installed" "$(capitalize "$manager_name")" "$not_installed_count" "$((uninstalled_count + not_installed_count))")"
    fi
    return 0
  else
    ui_indent "$(_f "%s: ✗ %d failed, %d uninstalled, %d not installed" "$(capitalize "$manager_name")" "$failed_count" "$uninstalled_count" "$not_installed_count")"
    return 1
  fi
}
