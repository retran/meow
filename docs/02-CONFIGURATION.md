# Configuration

The `.meow` framework can be customized through a combination of environment variables and configuration files located in the `private/` directory.

## The `.meowrc` File

The `.meowrc` file is the primary way to configure the behavior of `.meow`. This file is sourced by the `meowctl` script and can be used to set environment variables that control various features.

To get started, copy the example file:

```bash
cp private/meow/.meowrc.example private/meow/.meowrc
```

Then, edit `private/meow/.meowrc` to suit your preferences.

### Available Options

- `MEOW_ENABLE_MAS`: Set to `"true"` to enable package management from the Mac App Store using the `mas` command. Defaults to `"true"` on macOS.

**Example `.meowrc`:**

```bash
# Enable/disable Mac App Store (mas) package management
export MEOW_ENABLE_MAS="true"
```

**Note on `.meowrc` Variables:** Variables defined in your `.meowrc` file are loaded into your `zsh` profile (`config/zsh/.zprofile`) upon startup. This makes them globally available within your shell environment, not just for the `meowctl` utility.

## Secrets Management

`.meow` provides a simple mechanism for managing secrets, such as API keys and tokens, that you might need for your development tools. These secrets are stored in the `private/secrets/` directory, which is ignored by Git to prevent accidental commits.

To configure your secrets, copy the example file:

```bash
cp private/secrets/.secrets.example private/secrets/.secrets
```

Then, edit the `private/secrets/.secrets` file and add your sensitive information. Components can then source this file to access the secrets they need.

## Git Configuration

You can maintain a separate Git configuration for your personal and work machines. `.meow` uses the `private/git/.gitconfig` file to store your Git user name and email.

Copy the example file:

```bash
cp private/git/.gitconfig.example private/git/.gitconfig
```

Then, edit `private/git/.gitconfig` with your details. This file will be symlinked to `$HOME/.gitconfig` by components that require it.

## Global Environment Variables

These environment variables can be set in your shell's environment to control `meowctl`.

- `MEOW`: The path to your `.meow` installation. Defaults to `$HOME/.meow`.
- `MEOW_VERBOSE`: Set to `true` for verbose output. Equivalent to the `--verbose` flag.
- `MEOW_DRY_RUN`: Set to `true` to simulate command execution. Equivalent to the `--dry-run` flag.

---

## See Also

The global configurations described here provide the foundation for your setup. To see how these settings are used and expanded upon, refer to the following guides:

- **[Presets](./03-PRESETS.md)**: Learn how components are grouped together, forming the basis of a complete setup.
- **[Component Development Guide](./08-COMPONENT-DEVELOPMENT.md)**: Understand how individual components can be configured and built.
