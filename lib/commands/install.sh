#!/usr/bin/env bash

# lib/commands/install.sh - Command library for installing dotfiles

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_COMMANDS_INSTALL_SOURCED:-}" ]]; then
    return 0
fi
_LIB_COMMANDS_INSTALL_SOURCED=1

source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/package/presets.sh"

_initialize_install_session() {
    setup_homebrew
}

_finalize_install_session() {
    cleanup_homebrew
}

_get_available_presets() {
    for file in "${MEOW}/presets"/*.yaml; do
        if [[ -f "$file" ]]; then
            echo "$(basename "$file" .yaml)"
        fi
    done
}

_validate_preset_exists() {
    local preset="$1"
    local indent_level="$2"
    local available_presets=()

    while IFS= read -r preset_name; do
        if [[ -n "$preset_name" ]]; then
            available_presets+=("$preset_name")
        fi
    done < <(_get_available_presets)

    if [[ " ${available_presets[*]} " =~ ${preset} ]]; then
        info "$indent_level" "Found preset: $preset"
        return 0
    else
        indented_warning "$indent_level" "Preset '$preset' not found. Available presets:"
        for preset_name in "${available_presets[@]}"; do
            list_item_msg "$((indent_level + 1))" "$preset_name"
        done
        return 1
    fi
}

_install_preset_content() {
    local preset="$1"
    local indent_level="$2"

    if ! apply_preset "$preset" "" "" "$indent_level"; then
        return 1
    fi

    save_installed_preset "$preset"
}

_report_install_results() {
    local preset="$1"
    local indent_level="$2"

    success_tick_msg "$indent_level" "Installation completed successfully with preset: $preset"
    info "$indent_level" "You may need to restart your shell for all changes to take effect."
    info "$indent_level" "Run 'source ~/.zshrc' to reload your shell configuration."
}

install_preset() {
    local preset="$1"
    local indent=0

    header "$indent" "Installing meow with preset: $preset"

    _validate_preset_exists "$preset" "$indent" || return 1

    _initialize_install_session
    _install_preset_content "$preset" "$indent" || return 1
    _finalize_install_session

    _report_install_results "$preset" "$indent"
}
