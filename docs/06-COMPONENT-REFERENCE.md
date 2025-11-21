# Component Reference

This document provides a detailed reference for all components available in the `.meow` framework.

---

## adaptive-keyboard-layouts

**Description:** USB keyboard detection and automatic layout switching via Hammerspoon.
**Type:** `hammerspoon`
**Platforms:** macOS
**Dependencies:** `hammerspoon`
**Configuration:**

- **Scripts:**
  - `setup.sh`: Restarts Hammerspoon to apply changes.
  - `macos_keyboard.sh`: Helper for setting layouts via `defaults`.
  - `set_das_keyboard_layouts.sh`: Sets layouts for Das Keyboard.
  - `set_mbp_keyboard_layouts.sh`: Sets layouts for MacBook Pro.
- **Lua:** `config/init.lua` (Hammerspoon watcher configuration).

---

## browsers

**Description:** Web browsers and related tools. Includes Google Chrome and browser extensions.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** _(File present but empty/comments only)_

---

## business-communication

**Description:** Business communication and collaboration applications. Includes professional tools for work environments (Slack, Zoom).
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `slack`, `zoom`

---

## desktop-essential

**Description:** Core desktop system utilities and essential GUI applications. Includes system management, app launcher, and basic desktop tools.
**Platforms:** macOS
**Dependencies:** `shell-essential`, `fonts`
**Packages:**

- **Homebrew:** `mas`
- **Mac App Store:** `Hidden Bar`, `RunCat`, `24 Hour Wallpaper`
  **Configuration:**
- **Scripts:** `setup.sh` (Configures macOS defaults for Finder, Dock, Input, etc.)

---

## desktop-utilities

**Description:** Desktop utility applications for system maintenance and file management.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `keka`

---

## development-essential

**Description:** Cross-language development tools for version control, project management, and code collaboration.
**Platforms:** macOS, Linux
**Dependencies:** `go-task`, `js-toolchain`, `neovim`
**Packages:**

- **APK:** `yamllint`, `httpie`
- **APT:** `yamllint`, `httpie`
- **DNF:** `yamllint`, `httpie`
- **Homebrew:** `yamllint`, `httpie`
- **Pacman:** `yamllint`, `httpie`
- **NPM:** `prettier`, `jsonlint`
- **Pipx:** `codespell`
  **Configuration:**
- **Scripts:** `init.sh`

---

## docker-cli

**Description:** Docker CLI tools for remote container management from development environments.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **DNF:** `docker.io`, `docker-compose`

---

## docker-desktop

**Description:** OrbStack - lightweight Docker and Linux VMs for macOS.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `orbstack`
  **Configuration:**
- **Scripts:** `env.sh` (Sources OrbStack shell init)

---

## dotnet-development

**Description:** PowerShell tooling and VS Code enhancements for .NET developers.
**Platforms:** macOS, Linux
**Dependencies:** `dotnet-toolchain`
**Packages:**

- **VS Code:** `ms-dotnettools.csdevkit`, `ms-dotnettools.csharp`, `ms-dotnettools.vscode-dotnet-runtime`, `ms-vscode.powershell`
  **Configuration:**
- **Scripts:** `env.sh` (Configures DOTNET_CLI_TELEMETRY_OPTOUT)

---

## dotnet-toolchain

**Description:** .NET SDK installation sourced from Microsoft repositories across supported distributions.
**Platforms:** macOS, Linux (Debian, RHEL, Alpine)
**Dependencies:** `development-essential`
**Package Sources:** Defines Microsoft repositories for APT (Debian/Ubuntu).
**Configuration:**

- **Scripts:**
  - `env.sh`: Sets `DOTNET_ROOT` and `PATH`.
  - `preinstall.sh`: Installs Microsoft package repository (deb).
  - `setup.sh`: Installs .NET SDK via `dotnet-install.sh` script.

---

## fonts

**Description:** Developer fonts including Nerd Fonts for terminal applications.
**Platforms:** macOS
**Dependencies:** `shell-essential`
**Packages:**

- **Homebrew:** `font-fira-sans`, `font-jetbrains-mono`, `font-jetbrains-mono-nerd-font`, `font-fira-code-nerd-font`, `font-inconsolata-nerd-font`, `font-caskaydia-cove-nerd-font`, `font-caskaydia-mono-nerd-font`

---

## game-development

**Description:** Game creation tools including 3D modeling and engine support.
**Platforms:** macOS
**Dependencies:** `desktop-essential`, `development-essential`
**Packages:**

- **Homebrew:** `blender`
- **VS Code:** `alfish.godot-files`, `geequlim.godot-tools`, `pollywoggames.pico8-ls`

---

## gaming

**Description:** Gaming platforms and entertainment applications.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `nvidia-geforce-now`, `steam`

---

## go-development

**Description:** Go language servers, debugging tools, and workflow utilities layered on the go-toolchain.
**Platforms:** macOS, Linux
**Dependencies:** `go-toolchain`
**Packages:**

- **Go:** `dlv`, `staticcheck`, `golangci-lint`, `gofumpt`, `goimports`, `air`, `templ`, `swag`, `ginkgo`, `gotestsum`, `cobra-cli`, `cosign`, `syft`, `ko`
- **VS Code:** `golang.go`

---

## go-task

**Description:** Task runner CLI installed via Homebrew on macOS and Linux distributions using official repository setup scripts.
**Platforms:** macOS, Linux
**Packages:**

- **APK:** `task`
- **APT:** `task`
- **DNF:** `task`
- **Homebrew:** `go-task`
- **Pacman:** `task`
  **Configuration:**
- **Scripts:**
  - `preinstall.sh`: Configures Task repositories for APT/DNF.
  - `init.sh`: Enables zsh completion.

---

## go-toolchain

**Description:** Go runtime, GOPATH configuration, and compiler installation via system package managers.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`
**Packages:**

- **APK:** `go`
- **APT:** `golang-go`
- **DNF:** `golang`
- **Homebrew:** `go`
- **Pacman:** `go`
  **Configuration:**
- **Scripts:** `env.sh` (Configures GOPATH and PATH)

---

## hammerspoon

**Description:** Lua-based macOS automation framework for system customization.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `hammerspoon`
  **Configuration:**
- **Symlinks:** Links `config/hammerspoon` to `~/.hammerspoon`.
- **Lua:** `config/hammerspoon/init.lua` (Main loader for other components).

---

## js-development

**Description:** JavaScript/TypeScript language servers and developer tooling on top of the Node.js toolchain.
**Platforms:** macOS, Linux
**Dependencies:** `js-toolchain`
**Packages:**

- **NPM:** `typescript`, `ts-node`, `eslint`, `npm-check-updates`
- **VS Code:** `dbaeumer.vscode-eslint`, `christian-kohler.path-intellisense`
  **Configuration:**
- **Scripts:** `env.sh` (Configures NPM prefix and TS-Node cache).

---

## js-toolchain

**Description:** Node.js runtime, npm CLI, and JavaScript tooling prerequisites.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **APK:** `nodejs`, `npm`
- **APT:** `nodejs`, `npm`
- **DNF:** `nodejs`, `npm`
- **Homebrew:** `node`
- **Pacman:** `nodejs`, `npm`

---

## kotlin-development

**Description:** IntelliJ IDEA IDE for Kotlin development.
**Platforms:** macOS
**Dependencies:** `kotlin-toolchain`, `desktop-essential`
**Packages:**

- **VS Code:** `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`

---

## kotlin-toolchain

**Description:** JVM runtime and Kotlin compiler toolchain for command-line development.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`
**Packages:**

- **APK:** `openjdk21`, `kotlin`
- **APT:** `openjdk-21-jdk`, `kotlin`
- **DNF:** `java-21-openjdk`, `kotlin`
- **Homebrew:** `openjdk@21`, `kotlin`
- **Pacman:** `jdk-openjdk`, `kotlin`

---

## lua-development

**Description:** Lua language server, linting tools, and VS Code integration on top of lua-toolchain.
**Platforms:** macOS, Linux
**Dependencies:** `lua-toolchain`
**Packages:**

- **VS Code:** `sumneko.lua`

---

## lua-toolchain

**Description:** Lua runtime, headers, and luarocks package manager across supported platforms.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`
**Packages:**

- **APK:** `lua5.4`, `lua5.4-dev`, `luarocks`
- **APT:** `lua5.4`, `lua5.4-dev`, `luarocks`
- **DNF:** `lua`, `lua-devel`, `luarocks`
- **Homebrew:** `lua`, `luarocks`
- **Pacman:** `lua`, `luarocks`

---

## markdown

**Description:** Technical writing and documentation tools with linting and static site generation.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`, `js-toolchain`
**Packages:**

- **NPM:** `markdownlint-cli`, `@mermaid-js/mermaid-cli`

---

## media

**Description:** Media production and streaming tools.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `obs`
- **Mac App Store:** `GarageBand`

---

## meowvim

**Description:** Neovim configuration with git repository management and IDE-like features.
**Platforms:** macOS, Linux
**Dependencies:** `neovim`
**Configuration:**

- **Repository:** Clones `https://github.com/retran/meowvim` (branch: `dev`).
- **Symlinks:** Links repository to `~/.config/nvim`.
- **Scripts:** `cleanup.sh` (Cleans Neovim cache and state).

---

## meowvim-keyboard-layouts

**Description:** Vim mode-based keyboard layout switching for Neovide and Alacritty.
**Type:** `hammerspoon`
**Platforms:** macOS
**Dependencies:** `meowvim`, `adaptive-keyboard-layouts`
**Configuration:**

- **Scripts:** `setup.sh` (Restarts Hammerspoon).
- **Lua:** `config/init.lua` (Window title watcher for input switching).

---

## neovim

**Description:** Neovim text editor with essential plugins and configurations.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **APK:** `neovim`
- **APT:** `neovim`
- **DNF:** `neovim`
- **Homebrew:** `neovim`
- **Pacman:** `neovim`

---

## personal-communication

**Description:** Personal communication and messaging applications. Includes social and personal messaging tools (Discord, Telegram, WhatsApp).
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `discord`, `telegram`, `whatsapp`

---

## productivity

**Description:** Project management and workflow optimization tools.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `linear-linear`, `notion`, `drawio`
- **Mac App Store:** `Kindle`

---

## python-development

**Description:** Python developer tooling (pipx apps, language servers, VS Code extensions).
**Platforms:** macOS, Linux
**Dependencies:** `python-toolchain`
**Packages:**

- **Pipx:** `poetry`, `pipenv`
- **VS Code:** `ms-python.debugpy`, `ms-python.python`, `ms-python.vscode-pylance`

---

## python-toolchain

**Description:** Python runtime, pip/pipx tooling, virtualenv support, and Rye installer.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`
**Packages:**

- **APK:** `python3`, `py3-pip`, `py3-virtualenv`, `py3-wheel`
- **APT:** `python3`, `python3-pip`, `python3-venv`, `python3-virtualenv`, `python3-dev`, `cython3`, `pipx`
- **DNF:** `python3`, `python3-pip`, `python3-virtualenv`, `python3-devel`, `pipx`
- **Homebrew:** `python`, `pipx`, `pyenv`
- **Pacman:** `python`, `python-pip`, `python-virtualenv`, `python-pipx`
  **Configuration:**
- **Scripts:**
  - `env.sh`: Adds Rye shims to PATH.
  - `setup.sh`: Installs Rye.

---

## react-development

**Description:** React framework tools, testing utilities, and development scaffolding.
**Platforms:** macOS, Linux
**Dependencies:** `js-development`
**Packages:**

- **NPM:** `create-react-app`, `create-next-app`, `eslint-plugin-react`, `eslint-plugin-react-hooks`
- **VS Code:** `dsznajder.es7-react-js-snippets`, `formulahendry.auto-rename-tag`

---

## rust-development

**Description:** Cargo extensions, debugging helpers, and VS Code integration layered on rust-toolchain.
**Platforms:** macOS, Linux
**Dependencies:** `rust-toolchain`
**Packages:**

- **Cargo:** `cargo-watch`, `cargo-edit`, `cargo-expand`, `cargo-outdated`, `cargo-audit`, `cargo-deny`
- **VS Code:** `rust-lang.rust-analyzer`
  **Configuration:**
- **Scripts:** `cleanup.sh` (Cleans Cargo cache).

---

## rust-toolchain

**Description:** Rust toolchain bootstrap with rustup, clippy, and required system libraries.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`
**Packages:**

- **APK:** `build-base`, `pkgconf`, `openssl-dev`, `libssh2-dev`, `curl-dev`
- **APT:** `build-essential`, `pkg-config`, `libssl-dev`, `libssh2-1-dev`, `libcurl4-openssl-dev`
- **DNF:** `pkgconf-pkg-config`, `openssl-devel`, `libssh2-devel`, `libcurl-devel`, `gcc`, `gcc-c++`, `make`
- **Pacman:** `base-devel`, `pkgconf`, `openssl`, `libssh2`, `curl`
  **Configuration:**
- **Scripts:**
  - `env.sh`: Configures Cargo environment.
  - `setup.sh`: Installs `rustup` and default toolchain.

---

## shell-development

**Description:** Shell scripting tools including linting, formatting, and language server support.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`, `js-toolchain`
**Packages:**

- **APK:** `shellcheck`, `shfmt`
- **APT:** `shellcheck`, `shfmt`
- **Homebrew:** `shellcheck`, `shfmt`
- **Pacman:** `shellcheck`, `shfmt`
- **Pipx:** `yamllint`
- **VS Code:** `mads-hartmann.bash-ide-vscode`

---

## shell-essential

**Description:** Essential shell tools and development foundation for all environments. Includes git, node, bash/zsh, file navigation tools, and system monitoring utilities.
**Platforms:** macOS, Linux
**Packages:**

- **APK:** `curl`, `wget`, `git`, `git-lfs`, `nodejs`, `npm`, `py3-pip`, `py3-pipx`, `bash`, `zsh`, `coreutils`, `direnv`, `bat`, `fzf`, `ripgrep`, `zoxide`, `htop`, `findutils`, `watch`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship`
- **APT:** (Similar comprehensive list + `apt-transport-https`, `ca-certificates`, `gnupg`)
- **DNF:** (Similar comprehensive list + `eza`, `glow`, `procps` equivalent)
- **Homebrew:** (Similar comprehensive list)
- **Pacman:** (Similar comprehensive list)
  **Configuration:**
- **Symlinks:** `zsh` configs, `starship.toml`, `eza` config, `.gitconfig`, `.meowrc`.
- **Scripts:** `setup.sh` (Oh My Zsh, Tmux TPM), `init.sh`, `env.sh`, `cleanup.sh`.

---

## terminal-apps

**Description:** Terminal emulator applications and configurations. Includes Alacritty with custom configurations.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `alacritty`
  **Configuration:**
- **Symlinks:** Links `alacritty.toml` to `~/.config/alacritty/alacritty.toml`.

---

## time-tracking

**Description:** Time tracking desktop application. Includes Toggl Track desktop app for macOS.
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Mac App Store:** `Toggl Track`

---

## time-tracking-cli

**Description:** Time tracking command-line tools. Includes Toggl CLI for cross-platform time tracking.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **Pipx:** `togglcli`, `toggl`
  **Configuration:**
- **Symlinks:** `.togglrc`
- **Scripts:** `init.sh`, `cleanup.sh`.

---

## tmux

**Description:** Terminal multiplexer for advanced terminal session management.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **APK:** `tmux`
- **APT:** `tmux`
- **DNF:** `tmux`
- **Homebrew:** `tmux`
- **Pacman:** `tmux`
  **Configuration:**
- **Symlinks:** Links `.tmux.conf` to `~/.tmux.conf`.

---

## visual-studio-code

**Description:** Visual Studio Code IDE with essential extensions for development.
**Platforms:** macOS
**Dependencies:** `development-essential`
**Packages:**

- **Homebrew:** `visual-studio-code`
- **VS Code:** `github.codespaces`, `github.copilot`, `github.copilot-chat`, `github.vscode-github-actions`, `github.vscode-pull-request-github`, `enkia.tokyo-night`, `robbowen.synthwave-vscode`, `ms-azuretools.vscode-containers`
  **Configuration:**
- **Symlinks:** `settings.json`.

---

## visual-studio-code-cli

**Description:** Visual Studio Code CLI for tunnels and remote connections.
**Platforms:** Linux
**Dependencies:** `shell-essential`
**Configuration:**

- **Scripts:** `setup.sh` (Downloads and installs `code` binary).

---

## web-development

**Description:** Web development stack with CSS frameworks, build tools, and deployment utilities.
**Platforms:** macOS, Linux
**Dependencies:** `js-development`
**Packages:**

- **NPM:** `sass`, `tailwindcss`, `lighthouse`, `netlify-cli`
- **VS Code:** `formulahendry.auto-close-tag`, `ritwickdey.LiveServer`
