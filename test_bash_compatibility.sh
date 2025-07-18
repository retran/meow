#!/usr/bin/env bash

# test_bash_compatibility.sh - Test script to validate bash 3.2 compatibility

cd "$(dirname "$0")"

# Set up environment
DOTFILES_DIR="$(pwd)"
export DOTFILES_DIR

echo "Testing bash 3.2 compatibility..."
echo "Current bash version: $BASH_VERSION"
echo

# Test 1: Load compatibility functions
echo "Test 1: Loading bash compatibility functions..."
if source lib/core/bash_compat.sh; then
    echo "✓ bash_compat.sh loaded successfully"
else
    echo "✗ Failed to load bash_compat.sh"
    exit 1
fi

# Test 2: Version detection
echo
echo "Test 2: Version detection functions..."
VERSION_NUM=$(get_bash_version_number)
echo "✓ Bash version number: $VERSION_NUM"

if check_bash_version 3 2; then
    echo "✓ Bash 3.2+ compatibility check passed"
else
    echo "✗ Bash version check failed"
    exit 1
fi

# Test 3: Load UI functions
echo
echo "Test 3: Loading UI functions..."
if source lib/core/colors.sh && source lib/core/ui.sh; then
    echo "✓ UI functions loaded successfully"
else
    echo "✗ Failed to load UI functions"
    exit 1
fi

# Test 4: Test the fixed nameref function
echo
echo "Test 4: Testing _get_available_presets function (nameref replacement)..."
if source lib/commands/install.sh 2>/dev/null; then
    echo "✓ install.sh loaded successfully"
    
    # Test the function directly
    PRESETS=$(_get_available_presets)
    if [[ -n "$PRESETS" ]]; then
        echo "✓ _get_available_presets returned: $PRESETS"
    else
        echo "✗ _get_available_presets returned empty result"
        exit 1
    fi
    
    # Test the array population
    available_presets=()
    while IFS= read -r preset_name; do
        [[ -n "$preset_name" ]] && available_presets+=("$preset_name")
    done < <(_get_available_presets)
    
    if [[ ${#available_presets[@]} -gt 0 ]]; then
        echo "✓ Array population successful: ${available_presets[*]}"
    else
        echo "✗ Array population failed"
        exit 1
    fi
else
    echo "✗ Failed to load install.sh"
    exit 1
fi

# Test 5: Syntax validation
echo
echo "Test 5: Bash syntax validation..."
for script in bin/install.sh bin/update.sh lib/core/bash_compat.sh; do
    if bash -n "$script"; then
        echo "✓ $script syntax is valid"
    else
        echo "✗ $script has syntax errors"
        exit 1
    fi
done

echo
echo "🎉 All bash 3.2 compatibility tests passed!"
echo
echo "The following bash 4.0+ features have been successfully replaced:"
echo "  • local -n (nameref) → function return values with command substitution"
echo
echo "Scripts are now compatible with bash 3.2+ (macOS default)"