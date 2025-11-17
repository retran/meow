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
# @file: lib/core/tools.sh
# @brief: Tool availability checking and dependency management.
# @author: Andrew Vasilyev
# @license: MIT
#
if [ -n "${_LIB_CORE_TOOLS_SOURCED:-}" ]; then
  return 0
fi
_LIB_CORE_TOOLS_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/core/dry_run.sh"
source "${MEOW}/lib/core/platform.sh"

YQ_VERSION="${YQ_VERSION:-v4.47.1}"

# Detect operating system using POSIX-compliant uname
_detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "darwin" ;;
    *) echo "unknown" ;;
  esac
}

# Detect CPU architecture using POSIX-compliant uname
_detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64) echo "arm64" ;;
    armv7l) echo "arm" ;;
    *) echo "unknown" ;;
  esac
}

# Get installation directory with fallback
_get_install_dir() {
  if [ -w "/usr/local/bin" ] 2>/dev/null; then
    echo "/usr/local/bin"
  elif [ -w "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    echo "$HOME/.local/bin"
  else
    echo ""
  fi
}

ensure_yq() {
  local force_install=false

  # Check if yq exists and can parse basic YAML
  if command -v yq >/dev/null 2>&1; then
    # Test if yq can actually parse YAML correctly
    local test_yaml="/tmp/yq_test_$$.yaml"
    cat >"$test_yaml" <<'EOF'
test:
  - item1
  - item2
required:
  - shell-essential
  - development-essential
EOF

    local test_result
    test_result=$(yq eval '.required[]' "$test_yaml" 2>/dev/null || echo "")
    rm -f "$test_yaml"

    if [ -z "$test_result" ] || [ "$test_result" = "null" ]; then
      ui_action_warning "Found yq, but it cannot parse YAML correctly. Forcing reinstall from GitHub."
      force_install=true
    else
      local version_lines
      version_lines=$(echo "$test_result" | wc -l)
      if [ "$version_lines" -lt 2 ]; then
        ui_action_warning "Found yq, but it doesn't parse arrays correctly. Forcing reinstall from GitHub."
        force_install=true
      else
        ui_verbose_info "⇒ yq is working correctly."
        return 0
      fi
    fi
  else
    ui_action_warning "yq not found. Attempting installation via package manager."
    force_install=true
  fi

  if [ "$force_install" = "true" ]; then
    _install_yq_with_package_manager
  fi
}

_install_yq_with_package_manager() {
  if is_dry_run; then
    dry_run_ui_info "yq is missing and would be installed via the platform package manager."
    return 1
  fi

  local platform
  platform=$(get_platform)
  local sudo_cmd=""
  if command -v sudo >/dev/null 2>&1; then
    sudo_cmd="sudo"
  fi

  case "$platform" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        ui_action_start "Installing yq via Homebrew"
        if $sudo_cmd brew install yq >/dev/null 2>&1; then
          ui_action_success "yq installed with Homebrew."
          return 0
        fi
      fi
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        ui_action_start "Installing yq via apt-get"
        if $sudo_cmd apt-get install -y yq >/dev/null 2>&1; then
          ui_action_success "yq installed with apt-get."
          return 0
        fi
      elif command -v dnf >/dev/null 2>&1; then
        ui_action_start "Installing yq via dnf"
        if $sudo_cmd dnf install -y yq >/dev/null 2>&1; then
          ui_action_success "yq installed with dnf."
          return 0
        fi
      elif command -v pacman >/dev/null 2>&1; then
        ui_action_start "Installing yq via pacman"
        if $sudo_cmd pacman -Sy --noconfirm yq >/dev/null 2>&1; then
          ui_action_success "yq installed with pacman."
          return 0
        fi
      elif command -v apk >/dev/null 2>&1; then
        ui_action_start "Installing yq via apk"
        if $sudo_cmd apk add --no-cache yq >/dev/null 2>&1; then
          ui_action_success "yq installed with apk."
          return 0
        fi
      fi
      ;;
  esac

  ui_action_error "Unable to install yq automatically. Please install it via your package manager."
  return 1
}
