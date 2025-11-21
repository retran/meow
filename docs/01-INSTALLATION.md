# Installation Guide

This guide provides detailed instructions for installing the `.meow` framework.

## Prerequisites

Before you begin, ensure you have the following prerequisites installed on your system.

-   **`git`**: Required for cloning the repository.
-   **`curl`**: Required for some installation scripts and component downloads.
-   **A POSIX-compliant shell**: `.meow` is written in pure Shell and is compatible with Bash (version 3.2+) and Zsh.

## Quick Installation

The recommended way to install `.meow` is to clone the repository to `~/.meow` on your local machine.

```bash
git clone https://github.com/retran/meow.git ~/.meow
```

After cloning, `cd` into the directory:

```bash
cd ~/.meow
```

You can then execute the `meowctl` command directly from this directory:

```bash
./bin/meowctl list
```

## First Steps: Installing a Preset

Once `.meow` is cloned, your first step is to install a preset to configure your environment.

1.  **List Available Presets**:
    Use the [`list`](./04-COMMAND-REFERENCE.md#meowctl-list) command to see which presets are available.

    ```bash
    ./bin/meowctl list
    ```

2.  **Install a Preset**:
    Choose a preset and install it using the [`install`](./04-COMMAND-REFERENCE.md#meowctl-install) command. For a personal workstation, [`den-personal`](./03-PRESETS.md#the-den-host-configurations) is a great choice.

    ```bash
    ./bin/meowctl install den-personal
    ```

This command will begin the installation process, resolving dependencies, installing packages, running setup scripts, and creating symlinks.

## Shell Integration

For convenient access to `meowctl` from anywhere, you can add its `bin` directory to your shell's `PATH`.

Add the following line to your shell's configuration file (e.g., `~/.zshrc`, `~/.bash_profile`):

```bash
export PATH="$HOME/.meow/bin:$PATH"
```

After adding this line, restart your shell or source the configuration file, and you will be able to use `meowctl` as a global command.

---

## What's Next?

Now that you have installed the framework, the next logical step is to understand what you can install with it.

➡️ **[Learn about Presets](./03-PRESETS.md)** to choose the right configuration for your system.
