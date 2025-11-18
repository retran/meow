#!/usr/bin/env bash
set -euo pipefail

component="$1"
MEOW_ROOT="$2"

source "${MEOW_ROOT}/lib/core/ui.sh"
source "${MEOW_ROOT}/lib/core/dry_run.sh"
source "${MEOW_ROOT}/lib/core/platform.sh"

if ! meow_os_is_like "debian"; then
  exit 0
fi

codename="${MEOW_OS_VERSION_CODENAME:-${MEOW_OS_CODENAME:-plucky}}"
supported_codename="plucky"

if [ "$codename" != "$supported_codename" ]; then
  ui_verbose_info "Skipping dotnet 10 deb repo install: ubuntu codename '$codename' not supported."
  exit 0
fi

repo_url="https://packages.microsoft.com/config/ubuntu/25.04/packages-microsoft-prod.deb"
tmp_deb="$(mktemp -t packages-microsoft-prod.XXXXXX.deb)"
trap 'rm -f "$tmp_deb"' EXIT

if is_dry_run; then
  dry_run_ui_info "Would download $repo_url and install dotnet package repository."
  exit 0
fi

ui_step_header "Installing Microsoft package repository for .NET"
if ! curl -fsSL "$repo_url" -o "$tmp_deb"; then
  ui_error "Failed to download $repo_url"
  exit 1
fi

if ! sudo dpkg -i "$tmp_deb"; then
  ui_error "Failed to install packages-microsoft-prod package"
  exit 1
fi

ui_action_success "Microsoft package repository installed."
