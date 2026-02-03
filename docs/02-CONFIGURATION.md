# Configuration

The `.meow` framework can be customized through a combination of environment variables and configuration files located in the `private/` directory.

## The `config.yaml` File

The `config.yaml` file is the primary way to configure the behavior of `.meow`. This file is used by `meowctl` and shared by components to coordinate theme settings.

To get started, copy the example file:

```bash
cp private/meow/config.yaml.example private/meow/config.yaml
```

Then, edit `private/meow/config.yaml` to suit your preferences. The personal preset also ships an example at `presets/den-personal/config.yaml`.

### Theme Options

- `theme.mode`: `manual` or `auto`
- `theme.current`: `light` or `dark`
- `theme.light`: `preset` and `variant` for light mode
- `theme.dark`: `preset` and `variant` for dark mode

**Example `config.yaml`:**

```yaml
theme:
  mode: auto
  current: dark
  light:
    preset: catppuccin
    variant: latte
  dark:
    preset: catppuccin
    variant: mocha
```

**Note on `config.yaml`:** Changes to `config.yaml` require either a new terminal session or running `meowctl theme apply` to update active components.

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
