# Command Reference

This document provides a complete reference for all `meowctl` commands.

## Global Options

These options can be used with any command.

- `--verbose`, `-v`: Enables verbose output, showing detailed logs and command outputs.
- `--dry-run`: Simulates the command's execution without making any actual changes to the system. This is useful for previewing what will happen.
- `--help`, `-h`: Shows help information for a command.

---

## `meowctl install`

Installs a given preset.

### Usage

```bash
meowctl install <preset> [options]
```

### Arguments

- [`<preset>`](./03-USING-PRESETS.md): (Required) The name of the preset to install (e.g., `den-personal`).

### Options

- `--force`: Forces the re-installation of all components in the preset, even if they are already installed.

### Examples

```bash
# Install the professional den preset
meowctl install den-professional

# Force reinstall the Go litterbox preset with verbose output
meowctl install litterbox-go --force --verbose
```

---

## `meowctl uninstall`

Uninstalls a given preset or all presets.

### Usage

```bash
meowctl uninstall <preset|all> [options]
```

### Arguments

- `<preset|all>`: (Required) The name of the [preset](./03-USING-PRESETS.md) to uninstall, or `all` to uninstall all currently installed presets and components.

### Options

- `--force`: Forces the uninstallation of components, even if they are required by another installed preset or were installed manually.

### Examples

```bash
# Uninstall the personal den preset
meowctl uninstall den-personal

# Uninstall everything
meowctl uninstall all
```

---

## `meowctl update`

Updates installed components or presets.

### Usage

```bash
meowctl update [preset|all] [options]
```

### Arguments

- `[preset]`: (Optional) The name of the [preset](./03-USING-PRESETS.md) whose components you want to update.
- `all` or no argument: Updates all currently installed components across all presets.

### Options

- `--pull`: Performs a `git pull` on the `.meow` repository itself before running the update, ensuring the latest component and preset definitions are used.

### Examples

```bash
# Update all installed components
meowctl update

# Update the .meow repository and then update all components
meowctl update --pull

# Update only the components belonging to the 'den-personal' preset
meowctl update den-personal
```

---

## `meowctl list`

Lists all available [presets](./03-USING-PRESETS.md) and their installation status.

### Usage

```bash
meowctl list
```

### Status Indicators

- `✓`: The preset is installed.
- `❌`: The preset is not available on the current platform.
- (no icon): The preset is available but not installed.

### Example

```bash
meowctl list
```

---

## `meowctl component`

Manages individual [components](./09-COMPONENT-DEVELOPMENT.md) directly.

### `component list`

Lists all available components and their status.

- **Usage:** `meowctl component list [--names-only]`
- **Options:**
  - `--names-only`: Prints only the names of the components without status information.

### `component install`

Installs one or more components manually.

- **Usage:** `meowctl component install <component> [...]`
- **Arguments:**
  - `<component>`: (Required) The name of the component(s) to install.
- **Options:**
  - `--force`: Reinstalls the components even if they are already present.

### `component uninstall`

Uninstalls a component.

- **Usage:** `meowctl component uninstall <component> [--force]`
- **Arguments:**
  - `<component>`: (Required) The name of the component to uninstall.
- **Options:**
  - `--force`: Skips dependency checks. Use with caution, as this may break other components that depend on this one.

### `component update`

Updates one or more components.

- **Usage:** `meowctl component update <component> [...]`
- **Arguments:**
  - `<component>`: (Required) The name of the component(s) to update.

---

## `meowctl backup`

Manages backups of dotfiles that were replaced during symlinking.

### `backup list`

Lists all available backup files.

- **Usage:** `meowctl backup list [pattern]`
- **Arguments:**
  - `[pattern]`: (Optional) A search pattern to filter the list of backups.

### `backup restore`

Restores a specific dotfile from a backup file.

- **Usage:** `meowctl backup restore <file>`
- **Arguments:**
  - `<file>`: (Required) The full name of the backup file to restore (e.g., `.zshrc.backup.20231201_120000`).

---

## `meowctl help`

Shows help information for `meowctl` or a specific command.

### Usage

```bash
meowctl help [command]
```

### Example

```bash
# Show the main help message
meowctl help

# Show help for the 'install' command
meowctl help install
```

---

## See Also

If you encounter any issues while using these commands, the troubleshooting guide may have a solution.

➡️ **[Refer to the Troubleshooting Guide](./05-TROUBLESHOOTING.md)**
