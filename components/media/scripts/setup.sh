#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"

ui_action_start "TODO: write message - media_configuring"

if [[ -d "/Applications/OBS.app" ]]; then
  ui_info "TODO: write message - media_configuring_obs"

  obs_config_dir="$HOME/Library/Application Support/obs-studio"
  mkdir -p "$obs_config_dir/basic/scenes" 2>/dev/null || true
  mkdir -p "$obs_config_dir/basic/profiles" 2>/dev/null || true

  if [[ ! -f "$obs_config_dir/basic/scenes/Untitled.json" ]]; then
    cat > "$obs_config_dir/basic/scenes/Untitled.json" << 'EOF'
{
    "current_scene": "Scene",
    "current_transition": "Fade",
    "duplicate_sources": [],
    "groups": [],
    "modules": {
        "auto-scene-switcher": {
            "active": false,
            "interval": 300,
            "non_matching_scene": "",
            "switch_if_not_matching": false,
            "switches": []
        },
        "output-timer": {
            "autoStart": false,
            "autoStartRecordTimer": false,
            "autoStartStreamTimer": false
        }
    },
    "name": "Untitled",
    "preview_locked": false,
    "quick_transitions": [],
    "scene_order": [
        {
            "name": "Scene"
        }
    ],
    "sources": [],
    "transition_duration": 300,
    "transitions": []
}
EOF
  fi

  if [[ ! -f "$obs_config_dir/global.ini" ]]; then
    cat > "$obs_config_dir/global.ini" << 'EOF'
[General]
Name=Global
OutputMode=Simple
FilenameFormatting=%CCYY-%MM-%DD %hh-%mm-%ss
RecRBPrefix=Replay
RecRBSuffix=
OverwriteIfExists=false
RecFormat=mp4
RecTracks=1
FLVTrack=1
FFOutputToFile=true
FFFilePath=
FFFormat=
FFFormatMimic=
FFVEncoder=libx264
FFVEncoderId=0
FFAEncoder=aac
FFAEncoderId=0
EOF
  fi
fi

ui_action_success "TODO: write message - media_configured_successfully"
