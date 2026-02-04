# Troubleshooting

This guide provides solutions to common issues and offers general advice on how to debug problems with `.meow`.

## Common Issues

### "Command not found: meowctl"

If you see this error, it means the `meowctl` script is not in your shell's `PATH`.

- **Solution 1 (Recommended)**: Add `.meow` to your `PATH` by following the instructions in the [Installation Guide](./01-INSTALLATION.md#shell-integration).
- **Solution 2 (Workaround)**: Navigate to your `.meow` directory (`cd ~/.meow`) and run the command with a relative path: `./bin/meowctl`.

### A Component or Preset Fails to Install

Installation failures can happen for various reasons, such as a package server being down, a script error, or a network issue.

1.  **Run with Verbose Mode**: The first step is to re-run the command with the `--verbose` flag. This will provide detailed output from the installation scripts, which often reveals the exact point of failure.

    ```bash
    meowctl install <preset-name> --verbose
    ```

2.  **Check the Logs**: The full output of any failed command is logged. While `.meow` does not have a formal logging system to a file, the verbose output provides the necessary information.

### Update Conflicts (Uncommitted Changes)

When running `meowctl update --pull`, you might see an error message like "You have uncommitted changes."

This happens because `.meow` is a Git-based tool. To prevent losing your local modifications, the update command will not proceed if it detects uncommitted changes in your `.meow` repository.

- **Symptom**: `meowctl update --pull` fails with a message about uncommitted changes.
- **Solution**:
  1.  Commit your changes: If you intended to modify the framework, commit your work to your local Git repository.
  2.  Stash your changes: If your changes are temporary, use `git stash` to save them, run the update, and then apply them again with `git stash pop`.

      ```bash
      cd ~/.meow
      git stash
      meowctl update --pull
      git stash pop
      ```

### Configuration Issues

If you suspect that your configuration in `config.yaml` is not being loaded correctly, check the file for formatting errors or invalid YAML syntax. A common sign is that your theme settings are not being reflected in `meowctl` output.

## Debugging Techniques

### Use `--dry-run`

If you want to see what a command _would_ do without actually making any changes, use the `--dry-run` flag. This is incredibly useful for:

- Previewing which packages will be installed or uninstalled.
- Seeing which files will be symlinked.
- Confirming the order of operations.

```bash
meowctl install <preset-name> --dry-run
```

### Isolate the Problem

If an installation is failing, try to determine if the issue is with a specific component.

1.  Look at the output to see which component was being installed when the failure occurred.
2.  Try to install that component manually with `--verbose`:

    ```bash
    meowctl component install <component-name> --verbose
    ```

3.  If the component has its own `setup.sh` script, you can examine it to understand its logic.

### Check Permissions and `sudo` Access

Some installation issues can be caused by incorrect file or directory permissions. Ensure that your user has the necessary permissions to write to the directories where `.meow` is trying to install packages or create symlinks.

Additionally, many package installation scripts (`apt.sh`, `pacman.sh`, etc.) use `sudo` to install system-level packages. If your user does not have passwordless `sudo` configured, or if your `sudo` session has expired, the installation may hang while waiting for a password. Ensure your `sudo` access is correctly configured before running a large installation.

### Clear Caches for Synchronization Issues

If you're experiencing synchronization issues or unexpected behavior, try clearing `.meow`'s internal caches:

```bash
rm -f ~/.cache/meow-motd
rm -f ~/.sources
```

These caches store:
- `~/.cache/meow-motd`: Cached "Message of the Day" content
- `~/.sources`: Cached package source configurations

After clearing these caches, restart your shell or re-run `meowctl` commands. The framework will rebuild the caches with fresh data.

### Pipx Package Update Failures

When your Python version changes (e.g., upgrading from 3.13 to 3.14), pipx-managed packages may break with errors like:

```
✗ Failed to update Pipx codespell!
Error: /path/to/python: No module named pip
```

**Automatic Recovery (Built-in):**

As of recent updates, `.meow` automatically detects and fixes broken pipx virtual environments during `meowctl update` operations. When it encounters a "No module named pip" error, it will:

1. Detect the broken virtual environment
2. Automatically run `pipx reinstall <package>`
3. Continue with the update process

You don't need to take any manual action; the system handles this transparently.

**Manual Fix (if needed):**

If you encounter this issue outside of the update process, you can manually reinstall the affected package:

```bash
pipx reinstall <package-name>
# Example: pipx reinstall codespell
```

**Root Cause:**

This issue occurs when the Python interpreter version changes. Pipx creates virtual environments tied to specific Python versions, and when that version is no longer available, the virtual environment becomes unusable. The auto-recovery feature ensures your development tools remain functional after Python upgrades.

## Getting Help

If you've tried the steps above and are still stuck, please [open an issue](https://github.com/retran/meow/issues) on our GitHub repository.

When filing an issue, please include:

- The command you were trying to run.
- The full output from running the command with the `--verbose` flag.
- Your operating system and version.
- Any other relevant details about your environment.

---

## See Also

- **[Command Reference](./04-COMMAND-REFERENCE.md)**: Double-check the syntax and available options for the command you are running.
- **[Installation Guide](./01-INSTALLATION.md)**: Review the initial setup steps to ensure your environment is configured correctly.
