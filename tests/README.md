# Testing Infrastructure for meow

This directory contains the testing infrastructure for the meow dotfiles management system, with a focus on bash 3.2 compatibility.

## Test Files

- `bash_compat.bats` - Tests for bash version compatibility functions
- `here_strings.bats` - Tests for here-string compatibility fixes
- `integration.bats` - Integration tests for core functionality
- `comprehensive.bats` - Comprehensive tests for all refactored components
- `run_tests.sh` - Script to run all tests

## Running Tests

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Individual Test Files
```bash
bats tests/bash_compat.bats
bats tests/here_strings.bats
bats tests/integration.bats
bats tests/comprehensive.bats
```

## Requirements

- **bats** testing framework
- **bash 3.2** installed at `/tmp/bash32/bin/bash` (for compatibility testing)

### Installing bats
- Ubuntu/Debian: `sudo apt install bats`
- macOS: `brew install bats`

## Test Coverage

The tests verify:
- All shell scripts pass syntax check with bash 3.2
- No bash 4+ features remain in the codebase
- Here-strings have been replaced with compatible alternatives
- Core functions can be loaded and executed
- Version detection works correctly
- Shebang consistency across all scripts

## Bash 3.2 Compatibility

All tests are designed to run with bash 3.2 to ensure compatibility with macOS default shell environments.