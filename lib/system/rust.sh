#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_SYSTEM_RUST_SOURCED:-}" ]]; then
  return 0
fi
_LIB_SYSTEM_RUST_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

setup_rustup() {
  ui_step_header "$(get_static_message "rust_setting_up_toolchain")"

  if command -v rustup >/dev/null 2>&1; then
    if rustup show >/dev/null 2>&1; then
      ui_action_success "$(get_static_message "rust_toolchain_already_initialized")"
      install_rust_components
      return 0
    fi
  fi

  ui_spinner "$(get_static_message "rust_installing_toolchain")" \
    --success "$(get_static_message "rust_toolchain_installed")" \
    --fail "$(get_static_message "rust_toolchain_install_failed")" \
    rustup default stable

  if [[ $? -ne 0 ]]; then
    return 1
  fi

  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
  fi

  if command -v rustup >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then
    local rust_version
    rust_version=$(rustc --version 2>/dev/null || echo "unknown")
    ui_info "$(format_template_message "rust_version_info" "$rust_version")"

    install_rust_components

    ui_action_success "$(get_static_message "rust_toolchain_setup_complete")"
  else
    ui_warning "$(get_static_message "rust_toolchain_not_available")"
    ui_info "$(get_static_message "rust_restart_shell_notice")"
  fi
}

install_rust_components() {
  ui_step_header "$(get_static_message "rust_installing_components")"

  ui_spinner "$(get_static_message "rust_installing_clippy")" \
    --success "$(get_static_message "rust_clippy_installed")" \
    --fail "$(get_static_message "rust_clippy_install_failed")" \
    rustup component add clippy

  ui_spinner "$(get_static_message "rust_installing_analyzer")" \
    --success "$(get_static_message "rust_analyzer_installed")" \
    --fail "$(get_static_message "rust_analyzer_install_failed")" \
    rustup component add rust-analyzer

  if command -v rustfmt >/dev/null 2>&1; then
    ui_action_success "$(get_static_message "rust_rustfmt_available")"
  else
    ui_warning "$(get_static_message "rust_rustfmt_not_available")"
  fi
}
