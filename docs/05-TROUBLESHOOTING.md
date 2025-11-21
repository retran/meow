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

If you suspect that your configuration in `.meowrc` is not being loaded correctly, check for syntax errors in the file. A common sign of this is that environment variables you have set are not being reflected in the behavior of `meowctl`. The shell will often print syntax errors to your terminal when it tries to source the file, which can help you diagnose the problem.

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
