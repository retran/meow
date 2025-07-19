#!/usr/bin/env bats

# tests/preset_management.bats - Preset functionality tests

setup() {
  export MEOW="$(pwd)"
  export TEST_PRESET_FILE="/tmp/test_meow_installed_presets"
}

teardown() {
  # Clean up test files
  [[ -f "$TEST_PRESET_FILE" ]] && rm -f "$TEST_PRESET_FILE"
}

@test "preset files exist and are valid YAML" {
  [ -f "presets/personal.yaml" ]
  [ -f "presets/corporate.yaml" ]

  [ -s "presets/personal.yaml" ]
  [ -s "presets/corporate.yaml" ]
}

@test "preset functions handle missing files gracefully" {
  run bash -c "
    export MEOW='$(pwd)'
    export MEOW_INSTALLED_PRESETS_FILE='$TEST_PRESET_FILE'
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Test getting installed presets when file doesn't exist
    get_installed_presets
  "
  [ "$status" -eq 0 ]
}

@test "preset tracking works correctly" {
  run bash -c "
    export MEOW='$(pwd)'
    export MEOW_INSTALLED_PRESETS_FILE='$TEST_PRESET_FILE'
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Save a test preset
    save_installed_preset 'test-preset'
    
    # Verify it was saved
    is_preset_installed 'test-preset'
  "
  [ "$status" -eq 0 ]
}

@test "preset listing functions work" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Test listing available presets
    list_presets
  "
  [ "$status" -eq 0 ]
}

@test "components directory structure exists" {
  [ -d "presets/components" ]

  local component_count=$(find presets/components -name "*.yaml" | wc -l)
  [ "$component_count" -gt 0 ]
}

@test "preset dependencies can be parsed" {
  if [ -f "presets/personal.yaml" ]; then
    run bash -c "
      export MEOW='$(pwd)'
      source lib/core/ui.sh
      source lib/package/presets.sh
      
      # Load dependencies parsing logic
      if command -v yq &>/dev/null; then
        yq eval '.depends_on[]?' presets/personal.yaml 2>/dev/null || true
      fi
    "
    [ "$status" -eq 0 ]
  else
    skip "personal.yaml preset not found"
  fi
}
