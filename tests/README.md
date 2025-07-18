# Testing Framework

This directory contains functionality tests for the meow dotfiles management system.

## Overview

The testing framework validates core functionality and ensures the shell scripts work correctly across different environments.

## Test Files

- **`integration.bats`** - Integration tests for core functionality, library loading, and function verification
- **`run_tests.sh`** - Test runner script that executes all functionality tests

## Running Tests

### Prerequisites

Install the bats testing framework:

```bash
# Ubuntu/Debian
sudo apt install bats

# macOS
brew install bats
```

### Run All Tests

```bash
./tests/run_tests.sh
```

### Run Specific Tests

```bash
bats tests/integration.bats
```

## Test Structure

The tests verify:
- Core library loading and initialization
- UI function availability and basic operation
- Package management system functionality
- Integration between different components

## Adding New Tests

When adding new functionality to the codebase:
1. Add corresponding tests to verify the functionality works
2. Focus on testing behavior, not implementation details
3. Ensure tests are environment-agnostic
4. Update this README if new test files are added