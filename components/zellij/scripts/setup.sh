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
# @file: components/zellij/scripts/setup.sh
# @brief: Setup script for zellij - downloads required plugins, compiles daemon.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"

ZJSTATUS_URL="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
PLUGINS_DIR="${HOME}/.config/zellij/plugins"
ZJSTATUS_DEST="${PLUGINS_DIR}/zjstatus.wasm"
CONFIG_TEMPLATE="${MEOW}/components/zellij/config/zellij/config.kdl.template"
CONFIG_KDL_DEST="${HOME}/.config/zellij/config.kdl"
DAEMON_SRC="${MEOW}/components/zellij/daemon/zjstatus-daemon.swift"
DAEMON_BIN="${MEOW}/components/zellij/daemon/zjstatus-daemon"

# Render config.kdl.template to ~/.config/zellij/config.kdl, substituting the
# layout_dir and theme_dir placeholders with real absolute paths.
# zellij does not expand ~ in these fields, so absolute paths are required.
# config.kdl is NOT symlinked — it is generated here so the repo template stays clean.
render_config_kdl() {
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would render config.kdl.template -> ${CONFIG_KDL_DEST}"
    return 0
  fi

  if [ ! -f "${CONFIG_TEMPLATE}" ]; then
    ui_warning "config.kdl.template not found at ${CONFIG_TEMPLATE}, skipping config render"
    return 0
  fi

  local layouts_path="${HOME}/.config/zellij/layouts"
  local themes_path="${HOME}/.config/zellij/themes"

  mkdir -p "$(dirname "${CONFIG_KDL_DEST}")" || {
    ui_warning "Failed to create directory for config.kdl: $(dirname "${CONFIG_KDL_DEST}")"
    return 1
  }

  # If a symlink exists at the destination (from a previous install), remove it
  # so sed writes a fresh regular file rather than following the link into the repo.
  if [ -L "${CONFIG_KDL_DEST}" ]; then
    rm -f "${CONFIG_KDL_DEST}"
  fi

  sed \
    -e "s|layout_dir \".*\"|layout_dir \"${layouts_path}\"|" \
    -e "s|theme_dir \".*\"|theme_dir \"${themes_path}\"|" \
    "${CONFIG_TEMPLATE}" > "${CONFIG_KDL_DEST}"

  ui_action_success "Rendered config.kdl to ${CONFIG_KDL_DEST}"
}

setup_themes_dir() {
  local themes_src="${MEOW}/components/zellij/config/themes"
  local themes_link="${HOME}/.config/zellij/themes"

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would create themes dir symlink: ${themes_link} -> ${themes_src}"
    return 0
  fi

  mkdir -p "${themes_src}" || {
    ui_warning "Failed to create themes source directory: ${themes_src}"
    return 1
  }

  # Remove a plain directory (e.g. from a previous incomplete install) so we
  # can replace it with the symlink.  A symlink that already points to the
  # correct target is left untouched.
  if [ -d "${themes_link}" ] && [ ! -L "${themes_link}" ]; then
    rmdir "${themes_link}" 2>/dev/null || {
      ui_warning "themes dir ${themes_link} is not empty and not a symlink; skipping"
      return 1
    }
  fi

  if [ ! -L "${themes_link}" ]; then
    ln -s "${themes_src}" "${themes_link}" || {
      ui_warning "Failed to create themes symlink: ${themes_link} -> ${themes_src}"
      return 1
    }
    ui_action_success "Created themes symlink: ${themes_link} -> ${themes_src}"
  else
    ui_action_success "Themes symlink already exists: ${themes_link}"
  fi
}

install_zjstatus() {
  ui_step_header "Setting up zjstatus plugin"

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would create directory: ${PLUGINS_DIR}"
    ui_info "(dry-run) Would download zjstatus.wasm to: ${ZJSTATUS_DEST}"
    return 0
  fi

  mkdir -p "${PLUGINS_DIR}" || {
    ui_action_fail "Failed to create plugins directory: ${PLUGINS_DIR}"
    return 1
  }

  if [ -f "${ZJSTATUS_DEST}" ]; then
    ui_action_success "zjstatus.wasm already present at ${ZJSTATUS_DEST}"
    return 0
  fi

  ui_action_start "Downloading zjstatus.wasm..."

  local download_ok=false
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${ZJSTATUS_URL}" -o "${ZJSTATUS_DEST}" 2>&1 && download_ok=true
  elif command -v wget >/dev/null 2>&1; then
    wget -q "${ZJSTATUS_URL}" -O "${ZJSTATUS_DEST}" 2>&1 && download_ok=true
  else
    ui_action_fail "Neither curl nor wget found. Cannot download zjstatus.wasm."
    return 1
  fi

  if [ "$download_ok" = "false" ] || [ ! -f "${ZJSTATUS_DEST}" ]; then
    ui_action_fail "Failed to download zjstatus.wasm from ${ZJSTATUS_URL}"
    ui_warning "zjstatus plugin is required for the status bar. Start zellij with: zellij -l default"
    ui_warning "Re-run component setup once network is available, or manually place zjstatus.wasm at: ${ZJSTATUS_DEST}"
    rm -f "${ZJSTATUS_DEST}"
    return 1
  fi

  ui_action_success "zjstatus.wasm downloaded to ${ZJSTATUS_DEST}"
  return 0
}

build_daemon() {
  ui_step_header "Building zjstatus-daemon"

  if [ ! -f "${DAEMON_SRC}" ]; then
    ui_warning "zjstatus-daemon.swift not found at ${DAEMON_SRC}, skipping build"
    return 0
  fi

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would compile ${DAEMON_SRC} -> ${DAEMON_BIN}"
    return 0
  fi

  # Skip rebuild if binary is up-to-date
  if [ -f "${DAEMON_BIN}" ] && [ "${DAEMON_BIN}" -nt "${DAEMON_SRC}" ]; then
    ui_action_success "zjstatus-daemon already up-to-date"
    return 0
  fi

  if ! command -v swiftc >/dev/null 2>&1; then
    ui_warning "swiftc not found — cannot build zjstatus-daemon (install Xcode Command Line Tools)"
    return 1
  fi

  ui_action_start "Compiling zjstatus-daemon..."

  if swiftc \
      "${DAEMON_SRC}" \
      -framework Foundation \
      -framework Carbon \
      -framework SystemConfiguration \
      -framework IOKit \
      -O \
      -o "${DAEMON_BIN}" 2>&1; then
    strip "${DAEMON_BIN}" 2>/dev/null || true
    ui_action_success "zjstatus-daemon compiled to ${DAEMON_BIN}"
  else
    ui_action_fail "Failed to compile zjstatus-daemon"
    return 1
  fi
}

render_config_kdl
setup_themes_dir
if ! install_zjstatus; then
  ui_warning "zellij setup completed with warnings — zjstatus plugin is missing."
fi
if [[ "$(uname)" == "Darwin" ]]; then
  build_daemon
fi
