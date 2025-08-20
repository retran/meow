# 🐱 meow

> The purr-fect dotfiles management system that sets up your development
> environment with a single meow.

<div align="center">

![Shell](https://img.shields.io/badge/shell-%23019733.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)
![GitHub stars](https://img.shields.io/github/stars/retran/meow?style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/retran/meow?style=for-the-badge)

</div>

<div align="center">
<img src="assets/icon_small.png" alt="Meow Logo" width="200">
<br>
<strong>meow - Purr-fect Development Environment</strong>
</div>

`meow` was born from the desire to eliminate the repetitive and time-consuming
task of setting up a development environment from scratch. Instead of manually
installing packages, cloning repositories, and symlinking configuration files
for hours, **`meow` lets you do it all with a single command**.

It uses a powerful **preset system** to deploy a complete, tailored environment,
so you can get straight to coding. Whether you're setting up a new personal
laptop, a corporate workstation, or a disposable development container, `meow`
has a _purr-fect_ setup for you.

---

## Screenshots

<div align="center">

<img src="assets/screenshots/screenshot_login.png" alt="login"   width="800">
<img src="assets/screenshots/screenshot_update.png" alt="update" width="800">
<img src="assets/screenshots/screenshot_neovim.png" alt="vim"    width="800">

</div>

---

## Features

`meow` provides a comprehensive development-environment setup with these key
capabilities.

### Preset System

`meow` uses a **preset-based architecture** where presets are curated collections of components that work together to create complete development environments.

- **Presets** are complete environment configurations (e.g., `personal`, `corporate`, `litterbox-go`) that define which components to install
- **Components** are modular building blocks (e.g., `shell-essential`, `go-development`, `docker-cli`) that can be mixed and matched
- **Dependencies** are automatically resolved - components can depend on other components, ensuring consistent setups

**Available Presets:**

- **Personal** - Full-featured personal development environment with entertainment and social tools
- **Corporate** - Professional work environment with business communication tools
- **Litterbox Essential** - Minimal container-friendly base setup
- **Litterbox Go/Rust/Python/.NET** - Language-specific container environments
- **Litterbox Fullstack** - Complete full-stack development in containers

### Components

TODO what is components?

### Plugins

`meow` features a powerful **modular plugin system** that extends functionality
beyond core components. Plugins can integrate with Hammerspoon for macOS
automation or provide system-level tools and configurations.

#### Available Plugins

- **`adaptive-keyboard-layouts`** (Hammerspoon) – Intelligent keyboard layout
  switching that automatically detects connected USB keyboards and applies the
  appropriate layout configuration. Perfect for users with multiple keyboards
  who need different layout settings for external vs. built-in keyboards.

### Package Manager Integration

`meow` automatically detects and uses the appropriate package manager for each platform:

| Platform           | Package Manager                          |
| ------------------ | ---------------------------------------- |
| **macOS**          | Homebrew, mas (Mac App Store)            |
| **Ubuntu/Debian**  | apt                                      |
| **Alpine Linux**   | apk                                      |
| **Arch Linux**     | pacman                                   |
| **Cross-platform** | npm, pipx, cargo, go, VS Code extensions |

---

## Prerequisites

### Required

| Requirement  | Supported                                 |
| ------------ | ----------------------------------------- |
| **OS**       | macOS · Alpine · Debian/Ubuntu · Arch     |
| **Shell**    | Bash ≥ 3.2                                |
| **Internet** | Needed to download packages & tools       |
| **Git**      | For cloning the repository and submodules |

> **Bash compatibility:** `meow` works with the default Bash 3.2 that ships with
> macOS, avoiding the chicken-and-egg problem of needing a newer shell to
> install a newer shell.

---

## Getting Started

TODO rewrite
TODO first step is to download repository using curl or wget

1. **Choose your preset** – e.g. `personal`, `corporate`.
2. **Configure private settings** – Set up git and secrets from examples (required).
3. **Run the one-command setup** – copy/paste the snippet below.
4. **Restart your shell** – open a new terminal window.

### Configure Private Settings

Before installation, you need to configure your personal git and secrets settings:

```bash
# Clone the repository first
git clone --recursive https://github.com/retran/meow.git ~/.meow
cd ~/.meow

# Configure git settings (required)
cp private/git/.gitconfig.example private/git/.gitconfig
# Edit private/git/.gitconfig with your name and email

# Configure secrets (optional)
cp private/secrets/.secrets.example private/secrets/.secrets
# Edit private/secrets/.secrets with your API keys and tokens
```

**Important:** These configuration files are gitignored and contain your personal
information. Make sure to configure them before running the installation.

### Personal

```bash
cd ~/.meow && ./bin/meowctl install personal
```

### Corporate

```bash
~/.meow && cd ~/.meow && ./bin/meowctl install corporate
```

### Litterbox (Container-Friendly)

```bash
# Essential minimal setup
~/.meow && cd ~/.meow && ./bin/meowctl install litterbox-essential

# Language-specific containers
~/.meow && cd ~/.meow && ./bin/meowctl install litterbox-go
~/.meow && cd ~/.meow && ./bin/meowctl install litterbox-rust
```

### Keeping It Updated

```bash
cd ~/.meow
./bin/meowctl update --pull
```

The updater **pulls the latest changes** from git and reapplies the installation logic
for your preset, keeping packages and dependencies fresh.

---

## Usage

Your environment is ready to use as soon as the installer finishes.

### Main Commands

`meow` now uses a unified CLI tool called `meowctl` for all operations:

TODO add missing commands

```bash
# Install a preset
./bin/meowctl install <PRESET_NAME>

# Update all installed presets
./bin/meowctl update

# Update with git pull first
./bin/meowctl update --pull

# Update a specific preset
./bin/meowctl update <PRESET_NAME>

# Show installation status
./bin/meowctl status

# Manage plugins
./bin/meowctl plugin list
./bin/meowctl plugin enable <PLUGIN_NAME>
./bin/meowctl plugin disable <PLUGIN_NAME>

# Manage symlink backups
./bin/meowctl backup list
./bin/meowctl backup restore <BACKUP_FILE>

# Show help
./bin/meowctl --help
./bin/meowctl help <COMMAND>
```

---

## Presets and Components

`meow` uses a **layered component system** where each component can depend on others, creating a flexible and modular architecture.

### Architecture Overview

The `meow` architecture consists of three main layers:

1. **Presets Layer** - High-level environment configurations that users interact with

   - Combine multiple components into complete development environments
   - Handle platform-specific variations and user workflows
   - Examples: `personal`, `corporate`, `litterbox-go`

2. **Components Layer** - Modular building blocks that define specific functionality

   - Self-contained units with clear dependencies
   - Platform-agnostic definitions with platform-specific implementations
   - Examples: `shell-essential`, `go-development`, `docker-cli`

3. **Package Layer** - Platform-specific package lists and configurations

   - Actual package names for different package managers
   - Symlink configurations and dotfiles
   - VS Code extensions and language-specific tools

**Dependency Resolution:**

- Components declare dependencies on other components
- meow automatically resolves and installs dependencies in correct order
- Circular dependencies are detected and prevented
- Platform-specific variations are handled transparently

**Example Flow:**

```plain
User runs: ./bin/meowctl install personal
    ↓
Preset 'personal' depends on: shell-essential, desktop-essential, core-development...
    ↓
Component 'go-development' depends on: shell-essential, core-development
    ↓
Packages installed: homebrew/go-development.list, vscode/go-development.list
    ↓
Configuration files symlinked and applications configured
```

### Available Presets

TODO review and actualize

#### Desktop Presets

| Preset | Description | Components |
|--------|-------------|------------|
| **Personal** | Environment focused on development of pet projects and entertainment | `shell-essential`, `desktop-essential`, `personal-communication`, `productivity`, `media`, `gaming`, `core-development`, `docker-desktop`, `game-development`, `markdown` |
| **Corporate** | Work-focused development environment with professional tools | `shell-essential`, `desktop-essential`, `media`, `core-development`, `docker-desktop`, `markdown`, `corporate-communication`, `productivity` |

#### Container-Friendly Presets (Litterbox)

| Preset | Description | Components |
|--------|-------------|------------|
| **Litterbox Essential** | Minimal base setup, ideal for containers | `shell-essential`, `core-development`, `docker-cli`, `markdown` |
| **Litterbox Go** | Container-friendly Go environment | `shell-essential`, `core-development`, `go-development` |
| **Litterbox Rust** | Container-friendly Rust environment | `shell-essential`, `core-development`, `rust-development`, `docker-cli` |
| **Litterbox Python** | Container-friendly Python environment | `shell-essential`, `core-development`, `python-development`, `docker-cli` |
| **Litterbox .NET** | Container-friendly .NET environment | `shell-essential`, `core-development`, `dotnet-development`, `docker-cli` |
| **Litterbox Fullstack** | Full-stack development with Go backend and React frontend | `shell-essential`, `core-development`, `go-development`, `web-development`, `docker-cli`, `markdown` |

### Foundation Components

#### `shell-essential` - Essential Shell Tools

Core command-line utilities and shell environment for all platforms.

| Package Manager         | Packages                                                                                                                                                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Homebrew** (macOS)    | `bash`, `git`, `tmux`, `starship`, `neovim`, `fzf`, `ripgrep`, `zoxide`, `eza`, `bat`, `httpie`, `glow`, `zsh`, `curl`, `wget`, `direnv`, `watch`, `htop`                                                         |
| **APT** (Debian/Ubuntu) | `bash`, `git`, `tmux`, `starship`, `neovim`, `fzf`, `ripgrep`, `zoxide`, `eza`, `bat`, `httpie`, `glow`, `zsh`, `curl`, `wget`, `direnv`, `watch`, `htop`                                                         |
| **APK** (Alpine)        | `bash`, `curl`, `wget`, `direnv`, `watch`, `htop`, `eza`, `git`, `fd`, `fzf`, `ripgrep`, `zoxide`, `zsh`, `starship`, `neovim`, `httpie`, `bat`, `tmux`, `glow`                                                   |
| **Pacman** (Arch)       | `bash`, `curl`, `wget`, `direnv`, `watch`, `htop`, `eza`, `git`, `fd`, `fzf`, `ripgrep`, `zoxide`, `glow`, `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `tmux`, `starship`, `neovim`, `httpie`, `bat` |
| **NPM**                 | `@eslint/js`, `typescript`, `yaml-language-server`                                                                                                                                                                |

#### `core-development` - Universal Development Tools

Cross-language development essentials for version control and project management.

| Package Manager         | Packages                                      |
| ----------------------- | --------------------------------------------- |
| **Homebrew** (macOS)    | `gh`, `git-lfs`, `lazygit`, `go-task`         |
| **APT** (Debian/Ubuntu) | `github-cli`, `git-lfs`, `lazygit`, `go-task` |
| **APK** (Alpine)        | `github-cli`, `git-lfs`, `lazygit`, `go-task` |
| **Pacman** (Arch)       | `github-cli`, `git-lfs`, `lazygit`, `go-task` |
| **Pipx**                | `codespell`                                   |

#### `desktop-essential` - GUI Applications (macOS)

Essential desktop applications and system utilities.

| Package Manager        | Packages                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Homebrew**           | `mas`, `alacritty`, `raycast`, `google-chrome`, `bitwarden`, `appcleaner`, `visual-studio-code`, `drawio`                                  |
| **Mac App Store**      | Hidden Bar (1452453066), RunCat (1429033973), 24 Hour Wallpaper (1226087575)                                                               |
| **VS Code Extensions** | `github.codespaces`, `github.copilot`, `github.copilot-chat`, `enkia.tokyo-night`, `ms-azuretools.vscode-docker`, `esbenp.prettier-vscode` |

### Development Environment Components

#### `go-development` - Go Programming Language

Complete Go development environment with language server and tools.

| Package Manager             | Packages                                                                                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Runtime** (All Platforms) | `go`                                                                                                                                                               |
| **Go Tools**                | `gopls`, `dlv`, `staticcheck`, `golangci-lint`, `gofumpt`, `goimports`, `air`, `templ`, `swag`, `ginkgo`, `gotestsum`, `cobra-cli`, `goreleaser`, `cosign`, `syft` |
| **VS Code Extensions**      | `golang.go`                                                                                                                                                        |

#### `rust-development` - Rust Programming Language

Rust development environment with compiler and cargo tools.

**Runtime:** `rustup-init` (macOS), `rustup` (Linux), `rust` (Arch)

**Cargo Tools:**
`cargo-watch`, `cargo-edit`, `cargo-expand`, `cargo-outdated`, `cargo-audit`,
`cargo-deny`

**VS Code:**
`rust-lang.rust-analyzer`, `vadimcn.vscode-lldb`, `tamasfe.even-better-toml`

#### `js-development` - JavaScript/TypeScript

Modern JavaScript and TypeScript development environment.

| Package Manager        | Packages                                                                                                             |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **NPM**                | `typescript`, `ts-node`, `eslint`, `typescript-language-server`, `vscode-langservers-extracted`, `npm-check-updates` |
| **VS Code Extensions** | `dbaeumer.vscode-eslint`, `christian-kohler.path-intellisense`                                                       |

#### `python-development` - Python Programming

Python development environment with package management.

**Homebrew (macOS):** `pyenv`

**APT (Debian/Ubuntu):** `python3`, `python3-pip`, `pyenv`

**APK (Alpine):** `python3`, `python3-pip`

**Pacman (Arch):** `python`, `python-pip`, `pyenv`

**VS Code:** `ms-python.debugpy`, `ms-python.python`, `ms-python.vscode-pylance`

#### `kotlin-development` - Kotlin/JVM

Kotlin development environment with Java runtime and IDE tools.

| Package Manager         | Packages                                                                                                                         |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Homebrew** (macOS)    | `temurin@21`, `intellij-idea`                                                                                                    |
| **APT** (Debian/Ubuntu) | `openjdk-21-jdk`, `kotlin`                                                                                                       |
| **APK** (Alpine)        | `openjdk21-jdk`, `kotlin`                                                                                                        |
| **Pacman** (Arch)       | `jdk21-openjdk`, `kotlin`                                                                                                        |
| **VS Code Extensions**  | `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-test`, `vscjava.vscode-maven` |

#### `dotnet-development` - .NET Development

.NET development environment with SDK and PowerShell.

| Package Manager         | Packages                                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Homebrew** (macOS)    | `dotnet-sdk`, `powershell`                                                                                         |
| **APT** (Debian/Ubuntu) | `dotnet-sdk-8.0`, `powershell`                                                                                     |
| **APK** (Alpine)        | `dotnet6-sdk`                                                                                                      |
| **Pacman** (Arch)       | `dotnet-runtime`, `dotnet-sdk`, `powershell`                                                                       |
| **VS Code Extensions**  | `ms-dotnettools.csdevkit`, `ms-dotnettools.csharp`, `ms-dotnettools.vscode-dotnet-runtime`, `ms-vscode.powershell` |

#### `lua-development` - Lua Development

Lua runtime and development tools.

**Homebrew (macOS):** `lua-language-server`, `luacheck`, `luarocks`, `stylua`

**APT/APK/Pacman:** `lua` (runtime), similar tools

**VS Code:** `sumneko.lua`

#### `shell-development` - Shell Development Tools

Advanced shell scripting and development tools.

**Homebrew (macOS):** `shellcheck`, `shfmt`

**APT/APK/Pacman:** `shellcheck`, `shfmt`

**NPM:** `bash-language-server`

**Pipx:** `yamllint`

**VS Code:** `mads-hartmann.bash-ide-vscode`

#### `react-development` - React Framework

React development extending JavaScript component.

| Package Manager        | Packages                                                                                  |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **NPM**                | `create-react-app`, `create-next-app`, `eslint-plugin-react`, `eslint-plugin-react-hooks` |
| **VS Code Extensions** | `dsznajder.es7-react-js-snippets`, `formulahendry.auto-rename-tag`                        |

#### `web-development` - Advanced Web Development

Complete web development stack extending React.

| Package Manager        | Packages                                                |
| ---------------------- | ------------------------------------------------------- |
| **NPM**                | `sass`, `tailwindcss`, `lighthouse`, `netlify-cli`      |
| **VS Code Extensions** | `formulahendry.auto-close-tag`, `ritwickdey.LiveServer` |

#### `markdown` - Technical Writing

Documentation and technical writing tools.

| Package Manager        | Packages                                      |
| ---------------------- | --------------------------------------------- |
| **NPM**                | `markdownlint-cli`, `@mermaid-js/mermaid-cli` |
| **VS Code Extensions** | `yzhang.markdown-all-in-one`                  |

#### `fonts` - Typography

Essential fonts including Nerd Fonts for terminal and development.

| Package Manager      | Packages                                                                 |
| -------------------- | ------------------------------------------------------------------------ |
| **Homebrew** (macOS) | `font-fira-sans`, `font-jetbrains-mono`, `font-jetbrains-mono-nerd-font` |

#### `lua-development` - Lua Programming

Lua development environment and tools.

| Package Manager      | Packages                                                |
| -------------------- | ------------------------------------------------------- |
| **Homebrew** (macOS) | `lua-language-server`, `luacheck`, `luarocks`, `stylua` |

#### `shell-development` - Advanced Shell Tools

Advanced shell development and debugging tools.

| Package Manager         | Packages              |
| ----------------------- | --------------------- |
| **Homebrew** (macOS)    | `shellcheck`, `shfmt` |
| **APT** (Debian/Ubuntu) | `shellcheck`, `shfmt` |
| **APK** (Alpine)        | `shellcheck`, `shfmt` |
| **Pacman** (Arch)       | `shellcheck`, `shfmt` |

#### `node` - Node.js Runtime

Node.js runtime environment for JavaScript development.

| Package Manager         | Packages        |
| ----------------------- | --------------- |
| **Homebrew** (macOS)    | `node`          |
| **APT** (Debian/Ubuntu) | `nodejs`, `npm` |
| **APK** (Alpine)        | `nodejs`, `npm` |
| **Pacman** (Arch)       | `nodejs`, `npm` |

#### `pipx` - Python Package Manager

Python application installer and runner.

| Package Manager         | Packages      |
| ----------------------- | ------------- |
| **Homebrew** (macOS)    | `pipx`        |
| **APT** (Debian/Ubuntu) | `pipx`        |
| **APK** (Alpine)        | `pipx`        |
| **Pacman** (Arch)       | `python-pipx` |

#### `hammerspoon` - macOS Automation

Hammerspoon automation framework for macOS.

| Package Manager      | Packages      |
| -------------------- | ------------- |
| **Homebrew** (macOS) | `hammerspoon` |

#### `docker-desktop` - Docker Desktop

Docker desktop application with GUI.

| Package Manager      | Packages   |
| -------------------- | ---------- |
| **Homebrew** (macOS) | `orbstack` |

#### `corporate-communication` - Business Communication

Corporate and business communication tools.

| Package Manager      | Packages        |
| -------------------- | --------------- |
| **Homebrew** (macOS) | `slack`, `zoom` |

#### `personal-communication` - Personal Communication

Personal messaging and communication applications.

| Package Manager      | Packages                          |
| -------------------- | --------------------------------- |
| **Homebrew** (macOS) | `discord`, `telegram`, `whatsapp` |

#### `media` - Media Production

Media creation and streaming tools.

| Package Manager      | Packages |
| -------------------- | -------- |
| **Homebrew** (macOS) | `obs`    |

#### `gaming` - Gaming Applications

Gaming platforms and applications.

| Package Manager      | Packages                      |
| -------------------- | ----------------------------- |
| **Homebrew** (macOS) | `nvidia-geforce-now`, `steam` |

### Specialized Components

#### `docker-cli` - Docker Tools

Docker command-line tools for containerization.

| Package Manager         | Packages                      |
| ----------------------- | ----------------------------- |
| **APT** (Debian/Ubuntu) | `docker.io`, `docker-compose` |
| **APK** (Alpine)        | `docker-cli`                  |
| **Pacman** (Arch)       | `docker`, `docker-compose`    |

#### `game-development` - Game Creation Tools

Creative tools for game development.

| Package Manager        | Packages                                                               |
| ---------------------- | ---------------------------------------------------------------------- |
| **Homebrew** (macOS)   | `blender`, `krita`                                                     |
| **VS Code Extensions** | `alfish.godot-files`, `geequlim.godot-tools`, `pollywoggames.pico8-ls` |

#### `productivity` - Workflow Tools

Productivity and project management applications.

| Package Manager      | Packages                                     |
| -------------------- | -------------------------------------------- |
| **Homebrew** (macOS) | `linear-linear`, `notion`, `notion-calendar` |

---

## Creating Custom Presets and Components

TODO review and fix issues

`meow` allows you to create custom presets and components to tailor your development environment to specific needs.

### Creating Custom Components

Components are reusable units that define package installations and configurations for specific tools or development environments. Each component can specify dependencies on other components and define packages for different platforms.

**Component Purpose:**
- **Package Installation**: Define which packages to install via different package managers
- **Configuration Management**: Specify symlinks for configuration files
- **Dependency Resolution**: Declare dependencies on other components
- **Platform Support**: Handle platform-specific variations

Components are reusable units that define package installations and configurations. Each component can specify dependencies on other components and define packages for different platforms.

#### Component Structure

```yaml
# components/my-component/component.yaml
description: "Brief description of the component"

depends_on:
  - shell-essential
  - core-development

homebrew:
  packages:
    - my-component

apt:
  packages:
    - my-component

vscode:
  extensions:
    - my-component
```

#### Creating a Component

1. **Create component definition file** `components/my-custom-component/component.yaml`:

**File Location:** `components/my-custom-component/component.yaml`
**Content Example:**

2. **Define component structure**:

```yaml
description: "My custom development tools"

depends_on:
  - shell-essential

homebrew:
  packages:
    - my-custom-component

apt:
  packages:
    - my-custom-component

symlinks:
  configs:
    - my-custom-component
```

3. **Create package lists** for each platform:

**File Location:** `packages/homebrew/my-custom-component.list`
**Content Example:**
```text
jq
yq
terraform
kubectl
```

**File Location:** `packages/apt/my-custom-component.list`
**Content Example:**
```text
jq
yq-go
terraform
kubectl
```

**Note:** Each line contains one package name specific to that platform's package manager.

4. **Add VS Code extensions** (optional):

```bash
echo "publisher.extension-name" > packages/vscode/my-custom-component.list
```

5. **Create symlink configurations** (optional):

```yaml
# packages/symlinks/my-custom-component.yaml
- source: "$MEOW/config/my-tool/config.yaml"
  target: "$HOME/.config/my-tool/config.yaml"
```

The symlink configuration uses `$MEOW` environment variable to reference the meow installation directory and `$HOME` for the user's home directory.

### Creating Custom Presets

Presets combine multiple components into a complete development environment
setup. They provide a simple way to install everything needed for specific
use cases or environments.

#### Preset Structure

```yaml
# presets/my-preset/component.yaml
description: >-
  My custom development environment

depends_on:
  - shell-essential
  - core-development
  - my-custom-component
```

#### Creating a Preset

1. **Create preset file** in `presets/`:

```bash
touch presets/my-custom-preset/component.yaml
```

2. **Define preset composition**:

```yaml
description: >-
  Full-stack development with custom tools and configurations

depends_on:
  - shell-essential
  - core-development
  - js-development
  - react-development
  - docker-cli
  - my-custom-component
```

3. **Test your preset**:

```bash
./bin/meowctl install my-custom-preset
```

### Advanced Component Features

TOOD fix and move to custom components

Components can include initialization scripts and configuration files that are
automatically set up during installation:

```yaml
# components/my-component/component.yaml
description: "Custom component with advanced features"

depends_on:
  - core-development
  - shell-essential

homebrew:
  packages:
    - my-component

apt:
  packages:
    - my-component

symlinks:
  - my-component
```

#### Multi-Package Manager Support

```bash
# Different package managers for the same component
homebrew:
  packages:
    - shell-essential    # References packages/homebrew/shell-essential.yaml

apt:
  packages:
    - shell-essential    # References packages/apt/shell-essential.yaml

npm:
  packages:
    - shell-essential    # References packages/npm/shell-essential.yaml
```

#### Component Dependencies

Components like `shell-essential` demonstrate this pattern by providing complete
shell configurations including `.zshrc`, `.zshenv`, and initialization scripts
that set up the development environment automatically through the dependency
system.

#### Initialization Scripts and Configuration

Components can include initialization scripts and configuration files that are automatically set up during installation:

**Symlink Configuration Example:**
```yaml
# packages/symlinks/my-component.yaml
- source: "$MEOW/config/my-tool/config.yaml"
  target: "$HOME/.config/my-tool/config.yaml"
  backup: true
- source: "$MEOW/config/my-tool/init.sh"
  target: "$HOME/.my-tool-init"
  executable: true
```

**Shell Integration Example:**
```bash
# config/my-component/init.sh
#!/usr/bin/env bash
# Component initialization script

# Set environment variables
export MY_TOOL_CONFIG="$HOME/.config/my-tool"
export MY_TOOL_PATH="$HOME/.my-tool"

# Initialize tool on shell startup
if command -v my-tool >/dev/null 2>&1; then
    eval "$(my-tool init)"
fi

# Add custom aliases
alias mt='my-tool'
alias mtc='my-tool config'
```

**Configuration File Example:**
```yaml
# config/my-component/config.yaml
version: "1.0"
settings:
  auto_update: true
  theme: "tokyo-night"
  shortcuts:
    save: "Ctrl+S"
    quit: "Ctrl+Q"
```

Components like `shell-essential` demonstrate this pattern by providing complete shell configurations including `.zshrc`, `.zshenv`, and initialization scripts that set up the development environment automatically.

### Best Practices

#### Component Design

- **Single Responsibility**: Each component should have a focused purpose
- **Minimal Dependencies**: Only depend on components you actually need
- **Platform Support**: Test on all supported platforms when possible
- **Documentation**: Provide clear descriptions and usage examples

#### Preset Design

- **User-Focused**: Design presets around user workflows, not technical details
- **Environment-Specific**: Create different presets for different environments (personal, work, containers)
- **Modular**: Use components as building blocks rather than monolithic installations

#### File Organization

```text
components/
├── my-team-component.yaml        # Team-specific tools
├── my-project-component.yaml     # Project-specific setup
└── my-language-component.yaml    # Language-specific tools

presets/
├── my-team-preset.yaml          # Team development environment
├── my-project-preset.yaml       # Project-specific environment
└── my-minimal-preset.yaml       # Lightweight setup

packages/
├── homebrew/
│   ├── my-team-component.list
│   └── my-project-component.list
├── apt/
│   ├── my-team-component.list
│   └── my-project-component.list
└── symlinks/
    ├── my-team-component.yaml
    └── my-project-component.yaml
```

---

## Plugin System

The plugin system extends meow with custom functionality that requires runtime
integration or platform-specific behaviors. Unlike components (which manage
packages and configurations), plugins provide dynamic functionality through
two types:

### Plugin Types

TODO rethink plugins and fix this section

#### Hammerspoon Plugins

For macOS automation and window management:

- **Purpose**: Lua scripts that integrate with Hammerspoon
- **Use Case**: Dynamic system behaviors, keyboard shortcuts, window management
- **Example**: `adaptive-keyboard-layouts` automatically switches keyboard
layouts when external keyboards are connected/disconnected

#### Basic Plugins (Cross-Platform)

For cross-platform integrations:

- **Purpose**: Bundle related components with shared functionality
- **Use Case**: Complex workflows that span multiple tools
- **Example**: `toggl` integrates time tracking CLI and desktop app

### When to Use Plugins vs Components

**Use Plugins When:**

- You need runtime automation (Hammerspoon scripts)
- Bundling multiple related components into a workflow
- Platform-specific dynamic behaviors
- Custom system integrations

**Use Components When:**

- Installing packages and configuration files
- Static dotfile management
- Simple dependency management
- Cross-platform tool installation

### Plugin Types

#### Hammerspoon Plugins

- **Type**: `hammerspoon`
- **Purpose**: Extend Hammerspoon automation functionality
- **Loading**: Automatically loaded by Hammerspoon when enabled
- **Structure**: Must include `init.lua` with plugin logic

#### Basic Plugins

- **Type**: `basic`
- **Purpose**: Install system packages and manage configurations
- **Loading**: Dependencies installed during plugin setup
- **Structure**: Can include symlink configurations and package lists

## Creating Custom Plugins

1. **Create plugin directory**:

```bash
mkdir plugins/my-plugin
```

2. **Create plugin.yaml**:

```yaml
name: my-plugin
type: system
description: My custom plugin
platforms:
  - macos
components:
  - my-component
```

3. **For Hammerspoon plugins, add init.lua**:

```lua
local plugin = {}

function plugin.init()
    -- Initialization code
end

function plugin.cleanup()
    -- Cleanup code
end

return plugin
```

4. **Create component definition** in `components/my-component/component.yaml`

5. **Enable and test**:

```bash
./bin/meowctl plugin enable my-plugin
./bin/meowctl plugin install my-plugin
```

### Plugin Structure

```
plugins/
└── plugin-name/
    ├── plugin.yaml          # Plugin configuration
    ├── init.lua             # Main logic (Hammerspoon plugins)
    ├── config.lua           # Configuration (optional)
    ├── config/              # Configuration files
    └── packages/            # Package management
        └── symlinks/        # Symlink configurations
            └── plugin-name.yaml
```

---

## Getting Help

1. Check the **[Issues](https://github.com/retran/meow/issues)** page.
2. Review preset files in `presets/`.
3. Examine component definitions in `components/`.

---

## Contributing

Contributions are welcome to help improve `meow`! Here's how you can help:

### Ways to Contribute

- Report bugs & issues
- Suggest features or presets
- Improve documentation
- Submit pull requests
- Enhance configurations
- Add new package integrations

### Project Structure

```text
meow/
├── bin/                              # CLI tools
├── components/                       # Reusable component definitions
├── lib/                              # Core functionality libraries
│   ├── commands/                     # Install and update command logic
│   ├── core/                         # Platform detection, UI, session management
│   ├── motd/                         # Message of the day system
│   ├── package/                      # Package manager integrations
│   ├── plugin/                       # Plugin management system
│   └── system/                       # System-specific configurations
├── presets/                          # Preset definitions (component.yaml files)
├── packages/                         # Package lists for each manager
│   ├── homebrew/                     # macOS packages
│   ├── apt/                          # Debian/Ubuntu packages
│   ├── npm/                          # Node.js packages
│   ├── symlinks/                     # Symlink configurations
│   └── vscode/                       # VS Code extensions
├── plugins/                          # Plugin definitions
│   ├── adaptive-keyboard-layouts/    # Hammerspoon keyboard automation
│   ├── toggl/                        # Time tracking integration
│   └── README.md                     # Plugin development guide
├── private/                          # User-specific configurations (gitignored)
│   ├── git/                          # Git configuration (.gitconfig)
│   └── secrets/                      # Environment secrets (.secrets)
└── config/                           # Configuration files and dotfiles
```

---

## License

Licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

## Acknowledgments

`meow` builds on the excellent work of the open-source community. Huge thanks
to:

- [Homebrew](https://brew.sh/) • [Git](https://git-scm.com/) • [GitHub CLI](https://cli.github.com/)
- [tmux](https://github.com/tmux/tmux) • [Starship](https://starship.rs/) • [Neovim](https://neovim.io/)
- [Visual Studio Code](https://code.visualstudio.com/) • [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep) • [zoxide](https://github.com/ajeetdsouza/zoxide)
- [Go](https://golang.org/) • [Node.js](https://nodejs.org/) • [Rust](https://www.rust-lang.org/)
- [Raycast](https://raycast.com/) • [Hammerspoon](https://www.hammerspoon.org/)
- [Nerd Fonts](https://www.nerdfonts.com/)
- …and the many other projects that make development enjoyable.

---

### Author

`meow` is developed by Andrew Vasilyev with help from GitHub Copilot and feline
assistants Sonya Blade, Mila, and Marcus Fenix.

---

<div align="center">

**Happy coding with `project meow`! 🐱**

Made with ❤️ by Andrew Vasilyev and feline assistants

[Report Bug](https://github.com/retran/meow/issues) ·
[Request Feature](https://github.com/retran/meow/issues) ·
[Contribute](https://github.com/retran/meow/pulls)

</div>
