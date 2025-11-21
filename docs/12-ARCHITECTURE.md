# Concepts and Architecture

This document provides a deep-dive into the internal architecture of `.meow`.

## The Layered Design

`.meow` is built on a layered architecture that separates concerns, from high-level user commands down to the low-level details of package installation. This design makes the framework modular, extensible, and easy to maintain.

### 1. Orchestration Layer (`bin/meowctl`)

The Orchestration Layer is the user-facing entry point. The `bin/meowctl` script is a pure Bash script responsible for:

- **Parsing Command-Line Arguments**: It interprets user commands like `install`, `update`, and `component`, along with their flags (`--verbose`, `--dry-run`).
- **Loading Core Libraries**: It sources the necessary shell scripts from the `lib/` directory to perform its tasks.
- **Invoking Library Functions**: After parsing, it acts as a dispatcher, calling the appropriate functions from the `lib/` layer to execute the requested operation (e.g., calling `install_preset` from `lib/presets/presets.sh`).

It contains no business logic itself; its sole purpose is to orchestrate the work of the underlying layers.

### 2. Core Layer (`lib/core` and `lib/presets`, `lib/components`)

The Core Layer contains the primary business logic of the framework.

- `lib/core/`: This directory holds the foundational utilities required by the entire system.
  - `ui.sh`: Functions for logging, color-coded output, and user interface elements (spinners, headers).
  - `yaml.sh`: A simple YAML parser used to read `component.yaml` and `preset.yaml` files.
  - `platform.sh`: Detects the current operating system (macOS, Linux distribution) and sets global constants like `IS_MACOS`.
  - `dry_run.sh`: Implements the dry-run logic, allowing commands to be previewed without making changes.

  Other core scripts include `lib/env/env.sh`, which prepares the user's shell environment, and `lib/motd/motd.sh`, which handles the "Message of the Day" display.

- `lib/presets/` & `lib/components/`: These directories manage the lifecycle of presets and components, handling dependency resolution, topological sorting, and the execution of installation, update, and uninstallation logic.

### 3. Adapter Layer (`lib/package`)

The Adapter Layer is the key to `.meow`'s cross-platform package management. It provides a universal interface for installing packages, abstracting away the specifics of the underlying system's package manager.

The central script is `lib/package/common.sh`. It provides generic functions like `install_packages_generic`. This function takes a manager name (e.g., "homebrew", "apt") and the necessary commands as arguments.

The actual detection and loading of the correct "driver" happens within the component installation logic, which checks the platform and calls the appropriate package manager script (e.g., `lib/package/apt.sh`, `lib/package/homebrew.sh`). Each of these driver scripts then calls the generic functions in `common.sh` with the correct commands for that specific package manager. For example, `apt.sh` will call `install_packages_generic` with `apt-get install` as the install command.

This design allows adding support for a new package manager by simply creating a new driver script in `lib/package/` without changing the core installation logic.

## The Lifecycle of a Command: `meowctl install`

To understand how these layers work together, let's trace the execution of a [`meowctl install den-personal`](./04-COMMAND-REFERENCE.md#meowctl-install) command.

1.  **Parsing YAML**:
    - `meowctl` calls the `install_preset` function in `lib/presets/presets.sh`.
    - This function first reads the [`presets/den-personal/preset.yaml`](./08-PRESET-DEVELOPMENT.md) file.
    - It recursively follows the `extends` directives, parsing `presets/den-essential/preset.yaml` and `presets/base/preset.yaml` to gather the full list of `required` components.

2.  **Resolving Dependencies**:
    - For each component required by the preset, the system reads its [`components/.../component.yaml`](./09-COMPONENT-DEVELOPMENT.md#componentyaml) file.
    - It recursively reads the `depends_on` fields for each component, building a complete, flat list of all components needed for the installation.

3.  **Topological Sorting**:
    - Using the dependency graph constructed in the previous step, the `topological_sort_for_installation` function orders the components to ensure that dependencies are installed before the components that need them. For example, `shell-essential` will always come before components that depend on it.

4.  **Installing System Packages**:
    - The script iterates through the sorted list of components. For each component, it determines the platform and invokes the corresponding package manager scripts from `lib/package/`.
    - For example, on Ubuntu, it would invoke functions that use `apt.sh`. `apt.sh` then calls `install_packages_generic` from `common.sh`, passing `apt-get install` as the installation command.
    - Packages listed in the component's [`packages/apt.list`](./09-COMPONENT-DEVELOPMENT.md#packageslist) file are then installed.

5.  **Repository Cloning**:
    - If a component defines a `repository` section in its `component.yaml`, the framework clones the specified Git repository into the `.downloads` directory.
    - This step handles versioning (branch or tag) and ensures that external resources required by the component are available before setup scripts run.

6.  **Running Setup Scripts**:
    - After installing packages and cloning repositories, the component's lifecycle scripts are executed in order:
      - [`scripts/preinstall.sh`](./09-COMPONENT-DEVELOPMENT.md#installation-time-scripts) (if it exists)
      - [`scripts/setup.sh`](./09-COMPONENT-DEVELOPMENT.md#installation-time-scripts) (if it exists and the component is being installed for the first time)

7.  **Linking Dotfiles**:
    - Finally, the symlink logic in `lib/symlinks/symlinks.sh` is invoked.
    - It reads the YAML files in the component's [`symlinks/`](./09-COMPONENT-DEVELOPMENT.md#symlinksyaml) directory.
    - For each entry, it creates a symbolic link from the `source` in the repository to the `target` in the user's home directory, backing up any existing files.

8.  **Tracking Installation**:
    - Once all components are successfully installed, a symlink for the preset is created in the `.installed/presets` directory. This marks the preset as installed and is used by commands like `update` and `uninstall`.

---

## What's Next?

This document covers the "how" of `.meow`. To see how these architectural concepts are applied in practice, you should dive into the component development guide.

➡️ **[Learn How to Create and Structure Components](./09-COMPONENT-DEVELOPMENT.md)**
