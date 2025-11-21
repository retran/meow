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
# @file: components/python-toolchain/scripts/setup.sh
# @brief: Installs Rye using the official installer script when pipx cannot provide wheels on new Python versions.
# @author: Andrew Vasilyev
# @license: MIT
#
set -euo pipefail

component="$1"
MEOW_ROOT="$2"

source "${MEOW_ROOT}/lib/core/ui.sh"
source "${MEOW_ROOT}/lib/core/dry_run.sh"

if command -v rye >/dev/null 2>&1; then
  ui_verbose_action_success "Rye already installed; skipping installer."
  exit 0
fi

installer_url="https://rye-up.com/get"
install_dir="${HOME}/.rye"

if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
  ui_info "DRY-RUN: would download Rye installer from ${installer_url}"
  ui_info "DRY-RUN: would install Rye into ${install_dir}"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  ui_error "curl is required to install Rye via the official script."
  exit 1
fi

tmp_script="$(mktemp -t rye-install.XXXXXX)"
trap 'rm -f "$tmp_script"' EXIT

ui_step_header "Installing Rye via official installer"
if ! curl -fsSL "${installer_url}" -o "$tmp_script"; then
  ui_error "Failed to download Rye installer from ${installer_url}"
  exit 1
fi

chmod +x "$tmp_script"
if RYE_INSTALL_OPTION="--yes" "$tmp_script"; then
  ui_action_success "Rye installed successfully."
else
  ui_error "Rye installer script reported an error."
  exit 1
fi
