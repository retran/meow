#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: lib/doctor/doctor.sh
# @brief: Diagnostic checks for the meow installation.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_DOCTOR_SOURCED:-}" ]; then
  return 0
fi
_LIB_DOCTOR_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/defs.sh"
source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/yaml.sh"
source "${MEOW}/lib/components/core.sh"

# ---------------------------------------------------------------------------
# doctor_check_environment
# Verifies core environment variables and directory layout.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_environment() {
  ui_step_header "Environment"
  local errors_before="$MEOW_ERROR_COUNT"

  # MEOW variable
  if [ -z "${MEOW:-}" ]; then
    ui_action_error "MEOW environment variable is not set"
  elif [ ! -d "$MEOW" ]; then
    ui_action_error "$(printf "MEOW directory does not exist: %s" "$MEOW")"
  else
    ui_action_success "$(printf "MEOW=%s" "$MEOW")"
  fi

  # Platform info (informational, never an error)
  local platform
  platform=$(get_platform)
  ui_action_success "$(printf "Platform: %s" "$platform")"
  if [ -n "${MEOW_OS_ID:-}" ]; then
    ui_indent "$(printf "OS: %s %s" "$MEOW_OS_ID" "${MEOW_OS_VERSION_ID:-}")"
  fi

  # Required directories
  local dir label
  for dir_label in \
    "${MEOW}/bin:bin" \
    "${MEOW}/lib:lib" \
    "${MEOW_COMPONENTS_DIR}:components" \
    "${MEOW_PRESETS_DIR}:presets" \
    "${MEOW}/.installed:.installed"; do
    dir="${dir_label%%:*}"
    label="${dir_label##*:}"
    if [ -d "$dir" ]; then
      ui_action_success "$(printf "Directory exists: %s" "$label")"
    else
      ui_action_error "$(printf "Missing directory: %s (%s)" "$label" "$dir")"
    fi
  done

  # meowctl executable
  if [ -x "${MEOW}/bin/meowctl" ]; then
    ui_action_success "bin/meowctl is executable"
  else
    ui_action_error "bin/meowctl is missing or not executable"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_tools
# Verifies required external tools are present and functional.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_tools() {
  ui_step_header "Required Tools"
  local errors_before="$MEOW_ERROR_COUNT"

  # yq
  if command -v yq >/dev/null 2>&1; then
    local yq_version
    yq_version=$(yq --version 2>/dev/null | head -1 || echo "unknown")
    if _verify_yq 2>/dev/null; then
      ui_action_success "$(printf "yq: %s" "$yq_version")"
    else
      ui_action_error "$(printf "yq found but not working correctly: %s" "$yq_version")"
    fi
  else
    ui_action_error "yq: not found (required for YAML parsing)"
  fi

  # git
  if command -v git >/dev/null 2>&1; then
    local git_version
    git_version=$(git --version 2>/dev/null | head -1 || echo "unknown")
    ui_action_success "$(printf "git: %s" "$git_version")"
  else
    ui_action_error "git: not found"
  fi

  # curl
  if command -v curl >/dev/null 2>&1; then
    ui_action_success "curl: found"
  else
    ui_action_warning "curl: not found (needed for downloading tools)"
  fi

  # Platform-specific package manager
  if [ "$IS_MACOS" = "true" ]; then
    if command -v brew >/dev/null 2>&1; then
      local brew_version
      brew_version=$(brew --version 2>/dev/null | head -1 || echo "unknown")
      ui_action_success "$(printf "homebrew: %s" "$brew_version")"
    else
      ui_action_warning "homebrew: not found (macOS package manager)"
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    ui_action_success "apt-get: found"
  elif command -v dnf >/dev/null 2>&1; then
    ui_action_success "dnf: found"
  elif command -v pacman >/dev/null 2>&1; then
    ui_action_success "pacman: found"
  elif command -v apk >/dev/null 2>&1; then
    ui_action_success "apk: found"
  else
    ui_action_warning "no system package manager detected"
  fi

  # Cross-platform tools (optional — informational only)
  local optional_tool
  for optional_tool in mise pipx npm go cargo gem; do
    if command -v "$optional_tool" >/dev/null 2>&1; then
      ui_verbose_action_success "$(printf "%s: found" "$optional_tool")"
    else
      ui_verbose "$(printf "  %s: not found (optional)" "$optional_tool")"
    fi
  done

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_installed_tracking
# Checks that every symlink in .installed/components/ is valid and points
# to an existing component directory.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_installed_tracking() {
  ui_step_header "Installed Component Tracking"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    ui_action_warning "$(printf ".installed/components directory not found: %s" "$MEOW_INSTALLED_COMPONENTS_DIR")"
    return 0
  fi

  local found_any=false
  local broken_count=0
  local ok_count=0

  local entry
  while IFS= read -r -d '' entry; do
    local name
    name="$(basename "$entry")"
    found_any=true

    if [ -L "$entry" ]; then
      local link_target
      link_target="$(readlink "$entry")"
      if [ -d "$entry" ]; then
        ok_count=$((ok_count + 1))
        ui_verbose_action_success "$(printf "Tracking symlink OK: %s" "$name")"
      else
        broken_count=$((broken_count + 1))
        ui_action_error "$(printf "Broken tracking symlink: %s -> %s (target missing)" "$name" "$link_target")"
      fi
    else
      broken_count=$((broken_count + 1))
      ui_action_warning "$(printf "Unexpected non-symlink entry in .installed/components: %s" "$name")"
    fi
  done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$found_any" = "false" ]; then
    ui_info "No components are currently installed."
  elif [ "$broken_count" -eq 0 ]; then
    ui_action_success "$(printf "All %d component tracking symlinks are valid" "$ok_count")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_component_dependencies
# For each installed component, verifies its declared dependencies are also
# installed.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_component_dependencies() {
  ui_step_header "Component Dependencies"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    ui_info "No components installed — skipping dependency check."
    return 0
  fi

  local checked=0
  local issues=0

  local entry
  while IFS= read -r -d '' entry; do
    local component
    component="$(basename "$entry")"

    if ! is_component_installed "$component"; then
      continue
    fi

    local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
    if [ ! -f "$component_file" ]; then
      continue
    fi

    checked=$((checked + 1))

    if yaml_path_exists "$component_file" ".depends_on"; then
      local dep
      while IFS= read -r dep; do
        dep=$(printf '%s' "$dep" | tr -d '"')
        [ -z "$dep" ] && continue
        if ! is_component_installed "$dep"; then
          ui_action_error "$(printf "Component '%s' depends on '%s' which is not installed" "$component" "$dep")"
          issues=$((issues + 1))
        else
          ui_verbose_action_success "$(printf "Dependency OK: %s -> %s" "$component" "$dep")"
        fi
      done < <(read_yaml_array "$component_file" ".depends_on[]" 2>/dev/null)
    fi
  done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$checked" -eq 0 ]; then
    ui_info "No installed components found to check."
  elif [ "$issues" -eq 0 ]; then
    ui_action_success "$(printf "All dependencies satisfied (%d components checked)" "$checked")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_dotfile_symlinks
# For each installed component that declares symlinks, verifies the deployed
# dotfile symlinks in $HOME point to valid targets.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_dotfile_symlinks() {
  ui_step_header "Dotfile Symlinks"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    ui_info "No components installed — skipping dotfile symlink check."
    return 0
  fi

  local checked_files=0
  local ok_count=0
  local broken_count=0
  local missing_count=0

  local entry
  while IFS= read -r -d '' entry; do
    local component
    component="$(basename "$entry")"

    if ! is_component_installed "$component"; then
      continue
    fi

    local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"
    [ -d "$symlinks_dir" ] || continue

    local yaml_file
    while IFS= read -r -d '' yaml_file; do
      local num_symlinks
      num_symlinks=$(yaml_array_length "$yaml_file" 2>/dev/null || echo "0")
      local is_numeric=true
      case "$num_symlinks" in
        "" | *[!0-9]*) is_numeric=false ;;
      esac
      [ "$is_numeric" = "false" ] && continue
      [ "$num_symlinks" -eq 0 ] && continue

      checked_files=$((checked_files + 1))

      local i=0
      while [ "$i" -lt "$num_symlinks" ]; do
        local raw_target os_field
        raw_target=$(yaml_array_item "$yaml_file" "$i" "target" 2>/dev/null || echo "")
        os_field=$(yaml_array_item "$yaml_file" "$i" "os" 2>/dev/null || echo "any")
        [ -z "$os_field" ] && os_field="any"

        # Platform filter
        local should_check=false
        if [ "$os_field" = "any" ]; then
          should_check=true
        elif [ "$os_field" = "macos" ] && [ "$IS_MACOS" = "true" ]; then
          should_check=true
        elif [ "$os_field" = "linux" ] && [ "$IS_MACOS" != "true" ]; then
          should_check=true
        fi

        if [ "$should_check" = "true" ] && [ -n "$raw_target" ] && [ "$raw_target" != "null" ]; then
          local expanded_target
          expanded_target=$(eval echo "$raw_target" 2>/dev/null || echo "$raw_target")

          if [ -L "$expanded_target" ]; then
            local link_dest
            link_dest="$(readlink "$expanded_target")"
            if [ -e "$expanded_target" ]; then
              ok_count=$((ok_count + 1))
              ui_verbose_action_success "$(printf "Symlink OK: %s -> %s" "$expanded_target" "$link_dest")"
            else
              broken_count=$((broken_count + 1))
              ui_action_error "$(printf "Broken dotfile symlink: %s -> %s (target missing)" "$expanded_target" "$link_dest")"
            fi
          elif [ -e "$expanded_target" ]; then
            ui_action_warning "$(printf "Expected symlink but found plain file: %s (from component '%s')" "$expanded_target" "$component")"
            missing_count=$((missing_count + 1))
          else
            missing_count=$((missing_count + 1))
            ui_action_warning "$(printf "Missing dotfile symlink: %s (component '%s' not fully linked)" "$expanded_target" "$component")"
          fi
        fi

        i=$((i + 1))
      done
    done < <(find "$symlinks_dir" -name "*.yaml" -print0 2>/dev/null)
  done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$checked_files" -eq 0 ]; then
    ui_info "No components with dotfile symlinks found."
  elif [ "$broken_count" -eq 0 ] && [ "$missing_count" -eq 0 ]; then
    ui_action_success "$(printf "All %d dotfile symlinks are valid" "$ok_count")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_preset_tracking
# Checks that every symlink in .installed/presets/ is valid.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_preset_tracking() {
  ui_step_header "Installed Preset Tracking"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_PRESETS_DIR" ]; then
    ui_info "No presets installed."
    return 0
  fi

  local found_any=false
  local broken_count=0
  local ok_count=0

  local entry
  while IFS= read -r -d '' entry; do
    local name
    name="$(basename "$entry")"
    found_any=true

    if [ -L "$entry" ]; then
      local link_target
      link_target="$(readlink "$entry")"
      if [ -d "$entry" ]; then
        ok_count=$((ok_count + 1))
        ui_verbose_action_success "$(printf "Preset tracking symlink OK: %s" "$name")"
      else
        broken_count=$((broken_count + 1))
        ui_action_error "$(printf "Broken preset tracking symlink: %s -> %s (target missing)" "$name" "$link_target")"
      fi
    else
      broken_count=$((broken_count + 1))
      ui_action_warning "$(printf "Unexpected non-symlink entry in .installed/presets: %s" "$name")"
    fi
  done < <(find "$MEOW_INSTALLED_PRESETS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$found_any" = "false" ]; then
    ui_info "No presets are currently installed."
  elif [ "$broken_count" -eq 0 ]; then
    ui_action_success "$(printf "All %d preset tracking symlinks are valid" "$ok_count")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# _doctor_collect_tracked_packages <manager>
# Prints every package name tracked across INSTALLED component *.list files
# for the given package manager, one per line.  Version suffixes (tool@version)
# are stripped so names are comparable to what package managers report.
# Only components present in .installed/components/ are considered.
# ---------------------------------------------------------------------------
_doctor_collect_tracked_packages() {
  local mgr="$1"
  local pkg tool_name

  local entry
  while IFS= read -r -d '' entry; do
    local component
    component="$(basename "$entry")"

    # Skip entries that are not valid installed components
    is_component_installed "$component" 2>/dev/null || continue

    local list_file="${MEOW_COMPONENTS_DIR}/${component}/packages/${mgr}.list"
    [ -f "$list_file" ] || continue

    while IFS= read -r pkg || [ -n "$pkg" ]; do
      [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
      pkg=$(printf '%s' "$pkg" | xargs)
      [ -z "$pkg" ] && continue

      case "$mgr" in
        mas)
          # "1234567890 # App Name" — extract only the numeric ID
          tool_name="${pkg%%[[:space:]]*}"
          ;;
        mise)
          # "tool@version" or "prefix:tool@version" — bare tool name
          tool_name="${pkg%%@*}"
          ;;
        *)
          tool_name="$pkg"
          ;;
      esac

      printf '%s\n' "$tool_name"
    done < "$list_file"
  done < <(find "${MEOW_INSTALLED_COMPONENTS_DIR}" \
              -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# _doctor_audit_manager <label> <installed_list> <tracked_list>
# Generic helper: cross-references installed vs tracked for one manager.
# Increments the caller's orphan_count / missing_count variables via nameref.
# ---------------------------------------------------------------------------
_doctor_audit_manager() {
  local label="$1"
  local installed="$2"
  local tracked="$3"

  local pkg
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! printf '%s\n' "$tracked" | grep -qxF -- "$pkg"; then
      ui_action_warning "$(printf "%s: '%s' installed but not tracked in any component" "$label" "$pkg")"
      orphan_count=$((orphan_count + 1))
    else
      ui_verbose_action_success "$(printf "%s: '%s' tracked" "$label" "$pkg")"
    fi
  done <<< "$installed"

  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    if ! printf '%s\n' "$installed" | grep -qxF -- "$pkg"; then
      ui_action_warning "$(printf "%s: '%s' tracked in dotfiles but not installed" "$label" "$pkg")"
      missing_count=$((missing_count + 1))
    fi
  done <<< "$tracked"
}

# ---------------------------------------------------------------------------
# doctor_check_packages
# For each supported package manager, compares what is installed on the
# system against what is tracked in any component's package list.  Reports:
#   WARNING  — installed but not tracked in any component (orphan)
#   WARNING  — tracked in dotfiles but not currently installed (missing)
# Returns 1 if any warnings were emitted.
# ---------------------------------------------------------------------------
doctor_check_packages() {
  ui_step_header "Package Audit"
  local warnings_before="${MEOW_WARNING_COUNT:-0}"
  local orphan_count=0
  local missing_count=0
  local installed tracked

  # ------------------------------------------------------------------
  # Homebrew  (formulae leaves + casks, both tracked in homebrew.list)
  # ------------------------------------------------------------------
  if [ "$IS_MACOS" = "true" ] && command -v brew >/dev/null 2>&1; then
    local brew_formulae brew_casks
    brew_formulae=$(brew leaves --installed-on-request 2>/dev/null || true)
    brew_casks=$(brew list --cask -1 2>/dev/null || true)
    # Combine: formulae leaves + all casks
    installed=$(printf '%s\n%s\n' "$brew_formulae" "$brew_casks" \
      | grep -v '^$' | sort -u)
    tracked=$(_doctor_collect_tracked_packages "homebrew")
    _doctor_audit_manager "homebrew" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # Mac App Store  (compare by numeric ID)
  # ------------------------------------------------------------------
  if [ "$IS_MACOS" = "true" ] && command -v mas >/dev/null 2>&1; then
    # Cache full mas output once; use it for both ID list and name lookup
    local mas_full
    mas_full=$(mas list 2>/dev/null || true)
    installed=$(printf '%s\n' "$mas_full" | awk '{print $1}')
    tracked=$(_doctor_collect_tracked_packages "mas")

    # Orphans: installed but untracked — show app name for readability
    local id
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      if ! printf '%s\n' "$tracked" | grep -qxF -- "$id"; then
        local app_name
        app_name=$(printf '%s\n' "$mas_full" \
          | awk -v id="$id" '$1==id{$1=""; sub(/^ /,""); print; exit}')
        ui_action_warning "$(printf "mas: '%s' (%s) installed but not tracked in any component" \
          "$id" "$app_name")"
        orphan_count=$((orphan_count + 1))
      else
        ui_verbose_action_success "$(printf "mas: '%s' tracked" "$id")"
      fi
    done <<< "$installed"

    # Missing: tracked but not installed
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      if ! printf '%s\n' "$installed" | grep -qxF -- "$id"; then
        ui_action_warning "$(printf "mas: id '%s' tracked in dotfiles but not installed" "$id")"
        missing_count=$((missing_count + 1))
      fi
    done <<< "$tracked"
  fi

  # ------------------------------------------------------------------
  # apt (Debian/Ubuntu)
  # ------------------------------------------------------------------
  if command -v dpkg-query >/dev/null 2>&1; then
    installed=$(dpkg-query -f='${binary:Package}\t${Status}\n' -W 2>/dev/null \
      | awk '$2=="install" && $3=="ok" && $4=="installed" {print $1}' || true)
    tracked=$(_doctor_collect_tracked_packages "apt")
    _doctor_audit_manager "apt" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # apk (Alpine)
  # ------------------------------------------------------------------
  if command -v apk >/dev/null 2>&1; then
    installed=$(apk info 2>/dev/null || true)
    tracked=$(_doctor_collect_tracked_packages "apk")
    _doctor_audit_manager "apk" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # pacman (Arch)
  # ------------------------------------------------------------------
  if command -v pacman >/dev/null 2>&1; then
    installed=$(pacman -Qq 2>/dev/null || true)
    tracked=$(_doctor_collect_tracked_packages "pacman")
    _doctor_audit_manager "pacman" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # dnf / rpm (Fedora / RHEL)
  # ------------------------------------------------------------------
  if command -v rpm >/dev/null 2>&1; then
    installed=$(rpm -qa --qf '%{NAME}\n' 2>/dev/null || true)
    tracked=$(_doctor_collect_tracked_packages "dnf")
    _doctor_audit_manager "dnf" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # snap (Linux)
  # ------------------------------------------------------------------
  if command -v snap >/dev/null 2>&1; then
    installed=$(snap list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    tracked=$(_doctor_collect_tracked_packages "snap")
    _doctor_audit_manager "snap" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # npm globals
  # ------------------------------------------------------------------
  if command -v npm >/dev/null 2>&1; then
    installed=$(npm list -g --depth=0 --parseable 2>/dev/null \
      | grep 'node_modules/' | sed 's|.*/node_modules/||' || true)
    tracked=$(_doctor_collect_tracked_packages "npm")
    _doctor_audit_manager "npm" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # pipx
  # ------------------------------------------------------------------
  if command -v pipx >/dev/null 2>&1; then
    installed=$(pipx list --short 2>/dev/null | awk '{print $1}' || true)
    tracked=$(_doctor_collect_tracked_packages "pipx")
    _doctor_audit_manager "pipx" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # mise
  # ------------------------------------------------------------------
  if command -v mise >/dev/null 2>&1; then
    installed=$(mise ls 2>/dev/null | awk '{print $1}' | sort -u || true)
    tracked=$(_doctor_collect_tracked_packages "mise")
    _doctor_audit_manager "mise" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # cargo
  # ------------------------------------------------------------------
  if command -v cargo >/dev/null 2>&1; then
    installed=$(cargo install --list 2>/dev/null | awk '/:/ {print $1}' || true)
    tracked=$(_doctor_collect_tracked_packages "cargo")
    _doctor_audit_manager "cargo" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # gem  (skip when using macOS system Ruby — its GEM_HOME is flooded
  #       with stdlib entries that are not user-installed packages)
  # ------------------------------------------------------------------
  if command -v gem >/dev/null 2>&1; then
    local gem_home
    gem_home=$(gem env GEM_HOME 2>/dev/null || true)
    if [[ "$gem_home" == /Library/Ruby/* ]]; then
      ui_verbose "  gem: skipping audit (system Ruby at $gem_home)"
    else
      installed=$(gem list --no-versions 2>/dev/null || true)
      tracked=$(_doctor_collect_tracked_packages "gem")
      _doctor_audit_manager "gem" "$installed" "$tracked"
    fi
  fi

  # ------------------------------------------------------------------
  # luarocks  (exclude 'luarocks' itself — it is always self-present in
  #            the mise lua environment and is not a user-installed rock)
  # ------------------------------------------------------------------
  if command -v luarocks >/dev/null 2>&1; then
    installed=$(luarocks list --porcelain 2>/dev/null \
      | awk '{print $1}' | grep -v '^luarocks$' || true)
    tracked=$(_doctor_collect_tracked_packages "luarocks")
    _doctor_audit_manager "luarocks" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # VS Code extensions  (case-insensitive: normalise both lists to lower)
  # ------------------------------------------------------------------
  if command -v code >/dev/null 2>&1; then
    local vscode_installed_raw vscode_tracked_raw
    vscode_installed_raw=$(code --list-extensions 2>/dev/null || true)
    vscode_tracked_raw=$(_doctor_collect_tracked_packages "vscode")
    # Lowercase both sides so publisher casing differences don't cause
    # false orphan/missing reports (e.g. ritwickdey.LiveServer vs liveserver)
    installed=$(printf '%s\n' "$vscode_installed_raw" | tr '[:upper:]' '[:lower:]')
    tracked=$(printf '%s\n' "$vscode_tracked_raw" | tr '[:upper:]' '[:lower:]')
    _doctor_audit_manager "vscode" "$installed" "$tracked"
  fi

  # ------------------------------------------------------------------
  # Summary
  # ------------------------------------------------------------------
  if [ "$orphan_count" -eq 0 ] && [ "$missing_count" -eq 0 ]; then
    ui_action_success "All installed packages are tracked in dotfiles"
  else
    [ "$orphan_count" -gt 0 ] && ui_info "$(printf \
      "%d orphan(s) — installed but not tracked in any component" \
      "$orphan_count")"
    [ "$missing_count" -gt 0 ] && ui_info "$(printf \
      "%d missing — tracked in dotfiles but not installed" \
      "$missing_count")"
  fi

  local warnings_after="${MEOW_WARNING_COUNT:-0}"
  [ "$warnings_after" -eq "$warnings_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_manual_tracking
# Verifies that every entry in .installed/components-manual/ is:
#   1. A symlink (not a plain file/dir)
#   2. Has a corresponding entry in .installed/components/ (i.e. the component
#      is also formally installed, not just manually-marked)
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_manual_tracking() {
  ui_step_header "Manual Component Tracking"
  local errors_before="$MEOW_ERROR_COUNT"

  local manual_dir="${MEOW}/.installed/components-manual"

  if [ ! -d "$manual_dir" ]; then
    ui_info "No components-manual directory — skipping."
    return 0
  fi

  local found_any=false
  local ok_count=0
  local issues=0

  local entry
  while IFS= read -r -d '' entry; do
    local name
    name="$(basename "$entry")"
    found_any=true

    if [ ! -L "$entry" ]; then
      ui_action_error "$(printf \
        "Non-symlink entry in .installed/components-manual: %s" "$name")"
      issues=$((issues + 1))
      continue
    fi

    if ! [ -d "$entry" ]; then
      local link_target
      link_target="$(readlink "$entry")"
      ui_action_error "$(printf \
        "Broken manual tracking symlink: %s -> %s (target missing)" \
        "$name" "$link_target")"
      issues=$((issues + 1))
      continue
    fi

    if ! is_component_installed "$name"; then
      ui_action_error "$(printf \
        "Manual-install marker exists for '%s' but component is not installed in .installed/components/" \
        "$name")"
      issues=$((issues + 1))
    else
      ok_count=$((ok_count + 1))
      ui_verbose_action_success "$(printf "Manual tracking OK: %s" "$name")"
    fi
  done < <(find "$manual_dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$found_any" = "false" ]; then
    ui_info "No manually-installed components."
  elif [ "$issues" -eq 0 ]; then
    ui_action_success "$(printf \
      "All %d manual tracking entries are consistent" "$ok_count")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_component_yaml
# For each installed component, verifies that component.yaml exists and
# contains the minimum required fields (description).  Also checks that
# any scripts/ present are executable.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_component_yaml() {
  ui_step_header "Component YAML & Scripts"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    ui_info "No components installed — skipping."
    return 0
  fi

  local checked=0
  local issues=0

  local entry
  while IFS= read -r -d '' entry; do
    local component
    component="$(basename "$entry")"

    if ! is_component_installed "$component"; then
      continue
    fi

    checked=$((checked + 1))
    local comp_dir="${MEOW_COMPONENTS_DIR}/${component}"
    local comp_yaml="${comp_dir}/component.yaml"

    # component.yaml must exist
    if [ ! -f "$comp_yaml" ]; then
      ui_action_error "$(printf \
        "component.yaml missing for installed component: %s" "$component")"
      issues=$((issues + 1))
      continue
    fi

    # Must have a description field
    local desc
    desc=$(read_yaml_value "$comp_yaml" ".description" 2>/dev/null || true)
    if [ -z "$desc" ] || [ "$desc" = "null" ]; then
      ui_action_warning "$(printf \
        "component.yaml for '%s' has no 'description' field" "$component")"
      issues=$((issues + 1))
    else
      ui_verbose_action_success "$(printf "YAML OK: %s" "$component")"
    fi

    # Scripts that exist should be executable
    local script
    for script in preinstall.sh setup.sh cleanup.sh; do
      local script_path="${comp_dir}/scripts/${script}"
      if [ -f "$script_path" ] && [ ! -x "$script_path" ]; then
        ui_action_warning "$(printf \
          "Script not executable: %s/scripts/%s" "$component" "$script")"
        issues=$((issues + 1))
      fi
    done
  done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$checked" -eq 0 ]; then
    ui_info "No installed components to check."
  elif [ "$issues" -eq 0 ]; then
    ui_action_success "$(printf \
      "All %d installed component YAMLs and scripts are valid" "$checked")"
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_repositories
# For each installed component that declares a repository.url:
#   - Verifies that $MEOW/.downloads/<name>/ exists and is a git repo
# Also checks for stray entries in .downloads/ that have no corresponding
# installed component with a repository.
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_repositories() {
  ui_step_header "Component Repositories"
  local errors_before="$MEOW_ERROR_COUNT"

  # Collect set of component names that are installed AND have a repo url
  local repo_components=""

  if [ -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    local entry
    while IFS= read -r -d '' entry; do
      local component
      component="$(basename "$entry")"

      if ! is_component_installed "$component"; then
        continue
      fi

      local comp_yaml="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
      [ -f "$comp_yaml" ] || continue

      local repo_url
      repo_url=$(read_yaml_value "$comp_yaml" ".repository.url" 2>/dev/null || true)
      [ -z "$repo_url" ] || [ "$repo_url" = "null" ] && continue

      repo_components="${repo_components}${component}"$'\n'

      local download_dir="${MEOW_DOWNLOADS_DIR}/${component}"
      if [ ! -d "$download_dir" ]; then
        ui_action_error "$(printf \
          "Repository download missing for '%s': expected %s" \
          "$component" "$download_dir")"
      elif [ ! -d "${download_dir}/.git" ]; then
        ui_action_error "$(printf \
          "Download dir for '%s' is not a git repository: %s" \
          "$component" "$download_dir")"
      else
        ui_verbose_action_success "$(printf "Repository OK: %s" "$component")"
      fi
    done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  fi

  # Check for stray downloads (dirs with no installed+repo component)
  if [ -d "$MEOW_DOWNLOADS_DIR" ]; then
    local dl_entry
    while IFS= read -r -d '' dl_entry; do
      local dl_name
      dl_name="$(basename "$dl_entry")"
      if ! printf '%s\n' "$repo_components" | grep -qxF "$dl_name"; then
        ui_action_warning "$(printf \
          "Stray download directory with no installed component: .downloads/%s" \
          "$dl_name")"
      fi
    done < <(find "$MEOW_DOWNLOADS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_check_dotfile_sources
# For each dotfile symlink that IS correctly deployed (is a symlink), verifies
# that the symlink's source path actually exists.  A broken source means the
# symlink resolves to nothing even though the symlink itself exists.
# (Broken symlinks are already caught by doctor_check_dotfile_symlinks; this
# adds an extra cross-check on the source side for correctly-formed symlinks.)
# Returns 1 if any errors were detected.
# ---------------------------------------------------------------------------
doctor_check_dotfile_sources() {
  ui_step_header "Dotfile Symlink Sources"
  local errors_before="$MEOW_ERROR_COUNT"

  if [ ! -d "$MEOW_INSTALLED_COMPONENTS_DIR" ]; then
    ui_info "No components installed — skipping."
    return 0
  fi

  local ok_count=0
  local issues=0

  local entry
  while IFS= read -r -d '' entry; do
    local component
    component="$(basename "$entry")"

    if ! is_component_installed "$component"; then
      continue
    fi

    local symlinks_dir="${MEOW_COMPONENTS_DIR}/${component}/symlinks"
    [ -d "$symlinks_dir" ] || continue

    local yaml_file
    while IFS= read -r -d '' yaml_file; do
      local num_symlinks
      num_symlinks=$(yaml_array_length "$yaml_file" 2>/dev/null || echo "0")
      local is_numeric=true
      case "$num_symlinks" in
        "" | *[!0-9]*) is_numeric=false ;;
      esac
      [ "$is_numeric" = "false" ] && continue
      [ "$num_symlinks" -eq 0 ] && continue

      local i=0
      while [ "$i" -lt "$num_symlinks" ]; do
        local raw_source raw_target os_field
        raw_source=$(yaml_array_item "$yaml_file" "$i" "source" 2>/dev/null || echo "")
        raw_target=$(yaml_array_item "$yaml_file" "$i" "target" 2>/dev/null || echo "")
        os_field=$(yaml_array_item "$yaml_file" "$i" "os" 2>/dev/null || echo "any")
        [ -z "$os_field" ] && os_field="any"

        # Platform filter
        local should_check=false
        if [ "$os_field" = "any" ]; then
          should_check=true
        elif [ "$os_field" = "macos" ] && [ "$IS_MACOS" = "true" ]; then
          should_check=true
        elif [ "$os_field" = "linux" ] && [ "$IS_MACOS" != "true" ]; then
          should_check=true
        fi

        if [ "$should_check" = "true" ] \
            && [ -n "$raw_source" ] && [ "$raw_source" != "null" ] \
            && [ -n "$raw_target" ] && [ "$raw_target" != "null" ]; then
          local expanded_source expanded_target
          expanded_source=$(eval echo "$raw_source" 2>/dev/null || echo "$raw_source")
          expanded_target=$(eval echo "$raw_target" 2>/dev/null || echo "$raw_target")

          # Only report if target is actually deployed as a symlink
          if [ -L "$expanded_target" ]; then
            if [ ! -e "$expanded_source" ]; then
              ui_action_error "$(printf \
                "Dotfile source missing: %s (for symlink %s, component '%s')" \
                "$expanded_source" "$expanded_target" "$component")"
              issues=$((issues + 1))
            else
              ok_count=$((ok_count + 1))
              ui_verbose_action_success "$(printf \
                "Source OK: %s" "$expanded_source")"
            fi
          fi
        fi

        i=$((i + 1))
      done
    done < <(find "$symlinks_dir" -name "*.yaml" -print0 2>/dev/null)
  done < <(find "$MEOW_INSTALLED_COMPONENTS_DIR" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  if [ "$issues" -eq 0 ] && [ "$ok_count" -gt 0 ]; then
    ui_action_success "$(printf \
      "All %d dotfile symlink sources are present" "$ok_count")"
  elif [ "$ok_count" -eq 0 ] && [ "$issues" -eq 0 ]; then
    ui_info "No deployed dotfile symlinks found to check sources for."
  fi

  [ "$MEOW_ERROR_COUNT" -eq "$errors_before" ] && return 0 || return 1
}

# ---------------------------------------------------------------------------
# doctor_run
# Runs all checks and prints a final summary.
# Returns 1 if any errors were found.
# ---------------------------------------------------------------------------
doctor_run() {
  local start_time
  start_time=$(date "+%s")

  ui_title "meow Doctor"
  ui_message ""

  doctor_check_environment
  ui_message ""

  doctor_check_tools
  ui_message ""

  doctor_check_installed_tracking
  ui_message ""

  doctor_check_manual_tracking
  ui_message ""

  doctor_check_component_yaml
  ui_message ""

  doctor_check_component_dependencies
  ui_message ""

  doctor_check_dotfile_symlinks
  ui_message ""

  doctor_check_dotfile_sources
  ui_message ""

  doctor_check_preset_tracking
  ui_message ""

  doctor_check_repositories
  ui_message ""

  doctor_check_packages
  ui_message ""

  if [ "$MEOW_ERROR_COUNT" -eq 0 ] && [ "${MEOW_WARNING_COUNT:-0}" -eq 0 ]; then
    show_final_summary "Doctor" "" "true" "$start_time"
    return 0
  else
    show_final_summary "Doctor" "" "false" "$start_time"
    return 1
  fi
}
