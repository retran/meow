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
# @brief: Setup script for zellij - downloads required plugins.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"

ZJSTATUS_URL="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
PLUGINS_DIR="${HOME}/.config/zellij/plugins"
ZJSTATUS_DEST="${PLUGINS_DIR}/zjstatus.wasm"

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

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${ZJSTATUS_URL}" -o "${ZJSTATUS_DEST}" 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q "${ZJSTATUS_URL}" -O "${ZJSTATUS_DEST}" 2>&1
  else
    ui_action_fail "Neither curl nor wget found. Cannot download zjstatus.wasm."
    return 1
  fi

  if [ $? -ne 0 ] || [ ! -f "${ZJSTATUS_DEST}" ]; then
    ui_action_fail "Failed to download zjstatus.wasm from ${ZJSTATUS_URL}"
    rm -f "${ZJSTATUS_DEST}"
    return 1
  fi

  ui_action_success "zjstatus.wasm downloaded to ${ZJSTATUS_DEST}"
  return 0
}

install_zjstatus || true
