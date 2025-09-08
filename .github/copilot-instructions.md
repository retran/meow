# Meow - Dotfiles Management System

**ALWAYS follow these instructions first** and fallback to additional search and context gathering only if the information here is incomplete or found to be in error.

Meow is a shell-based dotfiles management system that uses a component-based architecture to deploy complete development environments. It manages packages, configurations, and symlinks across multiple platforms (macOS, Linux distributions).

## Working Effectively

### Required Development Tools Installation
```bash
# Install go-task (required for all operations)
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Install linting tools
sudo apt-get install -y shellcheck yamllint luarocks
sudo luarocks install luacheck
```

### Environment Setup
```bash
# CRITICAL: Set MEOW environment variable when working in repository
export MEOW=/path/to/meow/repo

# Verify setup works
./bin/meowctl --help
task --list
```

### Build and Test Commands
```bash
# Run syntax validation with bash 3.2 compatibility - takes <1 second  
task test:syntax

# Run shell linting - takes 60-90 seconds, NEVER CANCEL. Set timeout to 180+ seconds.
task lint:shell

# Run YAML linting - takes 20-30 seconds, produces warnings about missing newlines (normal)
task lint:yaml

# Run Lua linting - takes <1 second
task lint:lua

# Run all linting - takes 90-120 seconds, NEVER CANCEL. Set timeout to 180+ seconds.  
task lint
```

### Application Commands and Usage
```bash
# CRITICAL: Always set MEOW environment variable first
export MEOW=/path/to/meow/repo

# List available presets - takes <1 second
./bin/meowctl list

# List available components - takes <1 second
./bin/meowctl component list

# Test installation with dry-run - takes 5-10 seconds for complex presets
./bin/meowctl install litterbox-essential --dry-run --verbose

# Install a component (simple test) - takes 30-60 seconds
./bin/meowctl component install pipx --verbose

# Install a preset - takes 2-5 minutes, may have package failures (normal in some environments)
./bin/meowctl install litterbox-essential --verbose
```

## Validation Scenarios

### ALWAYS validate changes with these scenarios:

1. **Syntax and Format Validation**:
   ```bash
   task test:syntax
   ```

2. **Basic Tool Functionality**:
   ```bash
   export MEOW=/path/to/meow/repo
   ./bin/meowctl --help
   ./bin/meowctl list
   ```

3. **Component System Test**:
   ```bash
   export MEOW=/path/to/meow/repo
   ./bin/meowctl component list
   ./bin/meowctl component install pipx --dry-run
   ```

4. **Linting Validation**:
   ```bash
   task lint  # Takes 90-120 seconds, set 180+ second timeout
   ```

### Expected Limitations
- Some components require packages not available in all environments (github-cli, lazygit)
- Personal/professional presets may fail on Linux (designed for macOS)
- YAML linting produces warnings about missing newlines at end of files (cosmetic, not breaking)
- Some shell linting warnings are expected and non-breaking

## Timing Expectations and Timeouts

**CRITICAL**: Set appropriate timeouts for all commands to prevent premature cancellation:

- **Basic commands** (list, help): 30 seconds timeout
- **Syntax tests**: 30 seconds timeout  
- **Shell linting**: 180+ seconds timeout, NEVER CANCEL
- **YAML linting**: 60+ seconds timeout, NEVER CANCEL
- **Lua linting**: 30 seconds timeout
- **All linting**: 180+ seconds timeout, NEVER CANCEL
- **Component installation**: 300+ seconds timeout, NEVER CANCEL
- **Preset installation**: 600+ seconds timeout, NEVER CANCEL

## Architecture and Key Files

### Project Structure
```
├── bin/meowctl              # Main command-line interface
├── Taskfile.yml            # Build automation (go-task)
├── lib/                    # Core shell libraries
│   ├── core/              # Bash utilities, UI functions
│   ├── components/        # Component management
│   ├── presets/          # Preset installation
│   ├── package/          # Package manager abstractions
│   └── symlinks/         # Dotfile symlinking
├── components/            # Modular component definitions
├── presets/              # Environment templates
└── .github/workflows/    # CI pipeline (shellcheck, yamllint)
```

### Main Command Interface
- **Primary tool**: `./bin/meowctl` (bash script)
- **Requires**: MEOW environment variable set to repository path
- **Dependencies**: bash ≥3.2, yq, package managers (apt/homebrew)

### Build System
- **Tool**: go-task (Taskfile.yml)
- **Key tasks**: lint (shell, yaml, lua), test:syntax
- **Dependencies**: shellcheck, yamllint, luacheck, go-task

## Common Tasks and Troubleshooting

### After Making Changes Always Run
```bash
# Validate changes
task test:syntax
task lint

# Test basic functionality  
export MEOW=$(pwd)
./bin/meowctl list
```

### When Adding New Components
1. Create component directory under `components/`
2. Add `component.yaml` with description and dependencies
3. Add package lists in `packages/` subdirectory
4. Test with: `./bin/meowctl component install <name> --dry-run`

### When Modifying Shell Scripts
1. Always validate with: `task test:syntax && task lint:shell`
2. Check CI requirements: `task lint`

### Platform Compatibility
- **Linux**: Most components work, some packages may be unavailable
- **macOS**: Full compatibility, requires Homebrew
- **Container environments**: Use litterbox-* presets for minimal setups

## Error Handling and Expected Failures

### Normal/Expected Failures
- Package installation failures for unavailable packages (github-cli, lazygit in some environments)
- Platform-specific preset failures (personal/professional on Linux)
- YAML linting warnings about missing newlines
- `dry_run_log: command not found` messages during dry-run mode (cosmetic, not breaking)
- VS Code CLI not found messages when VS Code isn't installed

### Critical Failures to Investigate
- Syntax errors in shell scripts
- Linting failures
- MEOW environment variable not set errors
- Missing required tools (task, shellcheck, etc.)
- Component dependency resolution errors

### Recovery Commands
```bash
# Clean up failed installations
./bin/meowctl uninstall all

# Verify environment setup
export MEOW=$(pwd)
./bin/meowctl --help
```

### Common Issues and Solutions

#### "MEOW environment variable not set"
```bash
# Solution: Always set MEOW to repository root
export MEOW=$(pwd)  # when in repo root
# or 
export MEOW=/full/path/to/meow/repo
```

#### "Failed to install APT github-cli" or similar package errors
- **Expected behavior** in many environments
- These packages may not be available in all repositories
- Installation continues for available packages
- Does not indicate a broken system

#### Component installation fails with dependency errors
```bash
# Check component dependencies
./bin/meowctl component list

# Try installing dependencies manually
./bin/meowctl component install pipx
./bin/meowctl component install node
```

## Repository Standards

### Code Style
- Shell scripts: Use shellcheck for linting
- YAML files: Use yamllint (warnings about newlines are acceptable)
- Lua files: Use luacheck for linting
- Indentation: 2 spaces for shell scripts

### Testing Requirements
- All shell scripts must pass syntax validation with bash 3.2 compatibility
- All changes must pass linting checks
- Component installations should be tested with dry-run
- Manual validation of command functionality required

### CI Pipeline
- Runs on: Ubuntu latest with bash 3.2 compatibility testing
- Checks: shellcheck, yamllint, luacheck, syntax tests
- Required tools: task, shellcheck, yamllint, luacheck
- Expected runtime: 2-3 minutes

Always run `task lint` before finalizing changes to ensure they meet repository standards.