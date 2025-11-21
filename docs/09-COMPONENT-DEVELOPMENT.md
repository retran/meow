# Component Development Guide

This guide provides a comprehensive overview of how to create and structure a component within the `.meow` framework.

## Anatomy of a Component

A component is a self-contained directory that encapsulates a specific piece of functionality, like a tool (`git`), a language runtime (`node`), or a configuration (`neovim`).

As a reference, we will look at the `shell-essential` component. Its structure is:

```
components/shell-essential/
├── component.yaml
├── packages/
│   ├── homebrew.list
│   └── apt.list
├── scripts/
│   └── setup.sh
└── symlinks/
    └── zsh.yaml
```

### `component.yaml`

This manifest file is the heart of the component. It defines the component's metadata and its relationship with other components.

**Schema:**

-   `description` (string): A brief, human-readable description of what the component does.
-   `platforms` (array, optional): Restricts the component to specific platforms. Can be `macos` or `linux`. If omitted, the component is considered universal.
-   `depends_on` (array, optional): A list of other components that must be installed before this one. The framework uses this to build a dependency graph and ensure correct installation order.

**Example (`components/shell-essential/component.yaml`):**

```yaml
description: Essential shell tools and development foundation for all environments.
  Includes git, node, bash/zsh, file navigation tools, and system monitoring utilities.
platforms:
- match:
    platform: macos
- match:
    platform: linux
```
*(Note: This foundational component has no dependencies.)*

### `packages/*.list`

The `packages/` directory contains lists of packages to be installed by different package managers. The file name corresponds to the package manager (e.g., `homebrew.list`, `apt.list`, `npm.list`).

**Format:**

The format is a simple text file with one package name per line. Comments starting with `#` are ignored.

**Example (`components/shell-essential/packages/homebrew.list`):**

```
curl
wget
git
git-lfs
node
pipx
direnv
# ... and so on
```

### Lifecycle Scripts

The `scripts/` directory can contain various lifecycle hooks that are executed at different points during the management of a component. This allows for complex setup, configuration, and cleanup operations.

There are two categories of scripts: installation-time and session-time.

#### Installation-Time Scripts

These scripts are executed during the `meowctl install` or `meowctl uninstall` process.

-   **`preinstall.sh`**: Runs *before* any packages for the component are installed. This is useful for adding third-party package repositories or running vendor-provided setup scripts that are prerequisites for the packages themselves.
-   **`setup.sh`**: Runs *after* packages have been successfully installed. This is the most common script, used for performing **one-time** setup tasks like configuring an application, installing plugins (e.g., for `tmux` or `zsh`), or setting system defaults. This script must be idempotent.
-   **`cleanup.sh`**: Runs when the component is being uninstalled via `meowctl uninstall`. Its purpose is to remove any files, directories, or configurations that were created by the `setup.sh` script, effectively reversing the setup process.

#### Session-Time Scripts (Shell Initialization)

These scripts are not run during installation, but are sourced by the user's shell (e.g., `.zshrc`, `.bash_profile`) every time a new session starts.

-   **`env.sh`**: Sourced for every new shell session. Its **only** purpose should be to export environment variables (e.g., `GOPATH`, `PATH` modifications). Because it's sourced, any other commands or output will affect the user's shell startup.
-   **`init.sh`**: Executed for every new shell session, after `env.sh`. This is for running commands that need to execute every time a new terminal is opened, such as starting a background service or printing a message. Use this script sparingly, as it can slow down shell startup.

**Key Requirements:**

-   **Idempotency**: `setup.sh` and `init.sh` scripts **must** be idempotent. They should be able to run multiple times without causing errors.
-   **Error Handling**: Use `set -e` at the beginning of your scripts to ensure they exit immediately on any error, which helps the framework manage state correctly.
-   **SDK Usage**: Use the `ui::` helper functions from `lib/core/ui.sh` for all output to maintain a consistent user experience.

**Example (`components/shell-essential/scripts/setup.sh`):**

This script checks if the `tmux` plugin manager is already installed. If it is, it reports success. If not, it installs it.

```bash
#!/usr/bin/env bash
set -e # Exit on error

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/ui.sh"

# ...

setup_tmux_plugin_manager() {
  ui_step_header "Setting up tmux Plugin Manager"

  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    ui_action_success "tmux Plugin Manager is already installed."
    # ... logic to update if it exists ...
    return 0
  fi

  ui_spinner "Installing tmux Plugin Manager..." \
    --success "tmux Plugin Manager installed." \
    --fail "Failed to install tmux Plugin Manager." \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
}
```

### `symlinks/*.yaml`

The `symlinks/` directory contains YAML files that define the symbolic links to be created for the component.

**Syntax:**

Each file contains a list of source-to-target mappings.

-   `source`: The absolute path to the file within your component's directory. It's best practice to use the `$MEOW` environment variable.
-   `target`: The absolute path to where the symlink should be created in the user's home directory. Use `$HOME` for portability.

The framework automatically handles backing up any existing files at the `target` location.

**Example (`components/shell-essential/symlinks/zsh.yaml`):**

```yaml
- source: "$MEOW/.installed/components/shell-essential/config/zsh/.zshrc"
  target: "$HOME/.zshrc"
- source: "$MEOW/.installed/components/shell-essential/config/zsh/.zprofile"
  target: "$HOME/.zprofile"
```

## Using the SDK: The `ui.sh` Library

When writing scripts, use the helper functions from [`lib/core/ui.sh`](./08-CONCEPTS-AND-ARCHITECTURE.md#2-core-layer-libcore-and-libpresets-libcomponents) for all output. This ensures that your component's output is consistent with the rest of the framework and respects the global `--verbose` and `--dry-run` flags.

Always source it at the top of your script:
`source "${MEOW}/lib/core/ui.sh"`

**Common Functions:**

-   `ui_info "Some message"`: General informational message.
-   `ui_success "Operation successful"`: A green success message.
-   `ui_error "Something went wrong"`: A red error message.
-   `ui_warning "This is a warning"`: A yellow warning message.
-   `ui_step_header "Step 1: Doing something"`: A bold header for a major step in your script.
-   `ui_action_start "Starting a task..."`: ➤ Indicates the start of an action.
-   `ui_action_success "Task complete"`: ✓ Indicates the successful completion of an action.
-   `ui_spinner "Doing work..." command_to_run`: Displays a spinner while `command_to_run` is executing, then shows a success or failure message.

## Best Practices

Follow these guidelines to create robust, maintainable components. These practices are direct applications of the project's core philosophy.

### Do

-   **Write Idempotent Scripts**: This is a core [principle](./07-PRINCIPLES.md). Always check for the existence of a file, package, or setting before attempting to install or create it.
-   **Use `set -e`**: Start all your shell scripts with `set -e` to ensure they fail fast.
-   **Use the `ui.sh` SDK**: Funnel all script output through the UI library to ensure [transparency](./07-PRINCIPLES.md#️-transparency).
-   **Check for Command Existence**: Before using a command (e.g., `git`, `tmux`), check if it's installed and in the user's `$PATH` using `command -v a_command >/dev/null 2>&1`.
-   **Keep Components Focused**: A component should do one thing well. A `go-toolchain` component should install Go, while a `go-development` component should install linters and debuggers.

### Don't

-   **Don't Assume `sudo`**: Never assume the user has `sudo` access or that it is passwordless. If an operation requires elevated privileges, the [package manager adapters](./08-CONCEPTS-AND-ARCHITECTURE.md#3-adapter-layer-libpackage) will handle it. For scripts, if `sudo` is required, you should prompt the user or provide instructions.
-   **Don't Write to Absolute Paths (Hardcoded)**: Always use variables like `$HOME` and `$MEOW` to construct paths.
-   **Don't Pollute the Global Namespace**: Keep variables and functions in your scripts specific and local where possible.
-   **Don't Clone Git Repositories Manually (for packages)**: If a tool can be installed via a package manager, prefer that method. Only use `git clone` in a `setup.sh` for things that are not available as packages, like `tpm` for `tmux`.

---

## See Also

To deepen your understanding, refer to the following documents:

-   **[Concepts and Architecture](./08-CONCEPTS-AND-ARCHITECTURE.md)**: Understand the layers and lifecycle that your component will be a part of.
-   **[Core Principles](./07-PRINCIPLES.md)**: Ensure your component aligns with the project's philosophy.
-   **[Presets](./03-PRESETS.md)**: See how components are bundled and used in real-world scenarios.
