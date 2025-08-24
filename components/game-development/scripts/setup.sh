#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

ui_action_start "$(fmt "game_dev_configuring")"

if [[ -d "/Applications/Blender.app" ]]; then
  ui_info "$(fmt "game_dev_configuring_blender")"

  blender_scripts_dir="$HOME/Library/Application Support/Blender/4.2/scripts"
  mkdir -p "$blender_scripts_dir/addons" 2>/dev/null || true
  mkdir -p "$blender_scripts_dir/startup" 2>/dev/null || true

  blender_config_dir="$HOME/Library/Application Support/Blender/4.2/config"
  mkdir -p "$blender_config_dir" 2>/dev/null || true

  if [[ ! -f "$blender_scripts_dir/startup/dev_setup.py" ]]; then
    cat > "$blender_scripts_dir/startup/dev_setup.py" << 'EOF'
import bpy

def setup_dev_environment():
    # Enable developer extras
    bpy.context.preferences.view.show_developer_ui = True

    # Set up viewport shading for game development
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                for space in area.spaces:
                    if space.type == 'VIEW_3D':
                        space.shading.type = 'MATERIAL'
                        break

setup_dev_environment()
EOF
  fi
fi

if [[ -d "/Applications/krita.app" ]]; then
  ui_info "$(fmt "game_dev_configuring_krita")"

  krita_resources_dir="$HOME/Library/Application Support/krita/resources"
  mkdir -p "$krita_resources_dir/brushes" 2>/dev/null || true
  mkdir -p "$krita_resources_dir/patterns" 2>/dev/null || true
  mkdir -p "$krita_resources_dir/gradients" 2>/dev/null || true

  krita_config_dir="$HOME/Library/Preferences"
  if [[ ! -f "$krita_config_dir/kritarc" ]]; then
    cat > "$krita_config_dir/kritarc" << 'EOF'
[General]
AutoSaveInterval=300
BackupFiles=true
BackupFilesCount=3
CreateBackups=true

[KoColor]
ColorManagementMode=2

[KritaShape/KisToolRectangle]
roundCornersX=0
roundCornersY=0

[canvas]
CanvasInputMode=0
ZoomMode=1
EOF
  fi
fi

ui_action_success "$(fmt "game_dev_configured_successfully")"
