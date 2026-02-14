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

## ai-tools

**Description:** AI-powered development tools including language models, code assistants, and AI CLI tools.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **Homebrew:** `llama.cpp`, `gemini-cli`, `copilot-cli`

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

- **Homebrew:** `keka`, `maccy`, `appcleaner`, `shottr`, `displayplacer`, `hiddenbar`

---

## development-essential

**Description:** Cross-language development tools for version control, project management, and code collaboration.
**Platforms:** macOS, Linux
**Dependencies:** `go-task`, `node-development`, `neovim`
**Packages:**

- **APK:** `httpie`
- **APT:** `httpie`
- **DNF:** `httpie`
- **Homebrew:** `httpie`, `opencode`, `pre-commit`
- **Pacman:** `httpie`
- **NPM:** `prettier`, `jsonlint`
- **Pipx:** `codespell`, `yamllint`
  **Configuration:**
- **Scripts:** `init.sh`
- **Pipx Auto-Recovery:**
  - Automatically detects broken pipx virtual environments (e.g., after Python version upgrades)
  - Runs `pipx reinstall` for packages with "No module named pip" errors
  - Maintains package functionality across Python version changes
  - Transparent recovery during `meowctl update` operations

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
**Dependencies:** `dotnet-runtime`
**Packages:**

- **VS Code:** `ms-dotnettools.csdevkit`, `ms-dotnettools.csharp`, `ms-dotnettools.vscode-dotnet-runtime`, `ms-vscode.powershell`
  **Configuration:**
- **Scripts:** `env.sh` (Configures DOTNET_CLI_TELEMETRY_OPTOUT)

---

## dotnet-runtime

**Description:** .NET runtime managed by mise.
**Platforms:** macOS, Linux
**Dependencies:** `tool-installers`
**Packages:**

- **Mise:** `dotnet@10`

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

- **Homebrew:** `blender`, `godot`
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

**Description:** Go language servers, debugging tools, and workflow utilities layered on the go-runtime.
**Platforms:** macOS, Linux
**Dependencies:** `go-runtime`
**Packages:**

- **Go:** `github.com/go-delve/delve/cmd/dlv`, `honnef.co/go/tools/cmd/staticcheck`, `github.com/golangci/golangci-lint/cmd/golangci-lint`, `mvdan.cc/gofumpt`, `golang.org/x/tools/cmd/goimports`, `github.com/air-verse/air`, `github.com/a-h/templ/cmd/templ`, `github.com/swaggo/swag/cmd/swag`, `github.com/onsi/ginkgo/v2/ginkgo`, `gotest.tools/gotestsum`, `github.com/spf13/cobra-cli`, `github.com/sigstore/cosign/v2/cmd/cosign`, `github.com/anchore/syft/cmd/syft`, `github.com/google/ko`
- **Homebrew:** `golangci-lint`, `sqlc`
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

## go-runtime

**Description:** Go runtime managed by mise.
**Platforms:** macOS, Linux
**Dependencies:** `tool-installers`
**Packages:**

- **Mise:** `go@1.25`

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

## node-development

**Description:** JavaScript/TypeScript language servers and developer tooling on top of the Node.js runtime.
**Platforms:** macOS, Linux
**Dependencies:** `node-runtime`
**Packages:**

- **NPM:** `typescript`, `ts-node`, `eslint`, `npm-check-updates`
- **VS Code:** `dbaeumer.vscode-eslint`, `christian-kohler.path-intellisense`
  **Configuration:**
- **Scripts:** `env.sh` (Configures NPM prefix and TS-Node cache).

---

## node-runtime

**Description:** Node.js runtime managed by mise.
**Platforms:** macOS, Linux
**Dependencies:** `tool-installers`
**Packages:**

- **Mise:** `node@lts`

---

## kotlin-development

**Description:** IntelliJ IDEA IDE for Kotlin development.
**Platforms:** macOS
**Dependencies:** `kotlin-toolchain`, `desktop-essential`
**Packages:**

- **Homebrew:** `gradle`
- **VS Code:** `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-dependency`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`

---

## kotlin-toolchain

**Description:** JVM runtime and Kotlin compiler toolchain for command-line development.
**Platforms:** macOS, Linux
**Dependencies:** `development-essential`, `java-runtime`
**Packages:**

- **APK:** `kotlin`
- **APT:** `kotlin`
- **DNF:** `kotlin`
- **Homebrew:** `kotlin`
- **Pacman:** `kotlin`

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
**Dependencies:** `development-essential`, `node-development`
**Packages:**

- **Homebrew:** `pandoc`, `mactex-no-gui`
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

**Description:** Neovim configuration with git repository management, IDE-like features, and terminal title integration.
**Platforms:** macOS, Linux
**Dependencies:** `neovim`
**Configuration:**

- **Repository:** Clones `https://github.com/retran/meowvim` (branch: `dev`).
- **Symlinks:** Links repository to `~/.config/nvim`.
- **Scripts:** `cleanup.sh` (Cleans Neovim cache and state).
- **Features:**
  - Adaptive terminal title format (short in tmux, verbose outside)
  - Title includes filename, modification status, and vim mode
  - Integrates with Hammerspoon for keyboard layout switching
  - Updates title on buffer changes, mode changes, and file saves

---

## meowvim-keyboard-layouts

**Description:** Vim mode-based keyboard layout switching via Hammerspoon for terminal applications (Ghostty, Alacritty).
**Type:** `hammerspoon`
**Platforms:** macOS
**Dependencies:** `meowvim`, `adaptive-keyboard-layouts`
**Configuration:**

- **Scripts:** `setup.sh` (Restarts Hammerspoon).
- **Lua:** `config/init.lua` (Window title watcher for input source switching based on vim mode).
- **Features:**
  - Detects vim mode from terminal window title (Normal, Insert, Visual, Command modes)
  - Automatically switches to English layout in Normal mode
  - Restores previous layout when entering Insert/Visual modes
  - Works with both traditional and adaptive title formats from neovim
  - Compatible with tmux sessions (short title format detection)

---

## neovim

**Description:** Neovim text editor with essential plugins and configurations.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **APK:** `neovim`
- **APT:** `neovim`
- **DNF:** `neovim`
- **Homebrew:** `neovim`, `tree-sitter-cli`
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

- **Homebrew:** `linear-linear`, `notion`, `drawio`, `canva`, `figma`
- **Mac App Store:** `Kindle`

---

## python-development

**Description:** Python developer tooling (pipx apps, language servers, VS Code extensions).
**Platforms:** macOS, Linux
**Dependencies:** `python-runtime`
**Packages:**

- **Pipx:** `poetry`, `pipenv`, `rye`
- **VS Code:** `ms-python.debugpy`, `ms-python.python`, `ms-python.vscode-pylance`

---

## python-runtime

**Description:** Python runtime managed by mise.
**Platforms:** macOS, Linux
**Dependencies:** `tool-installers`
**Packages:**

- **Mise:** `python@3`

---

## react-development

**Description:** React framework tools, testing utilities, and development scaffolding.
**Platforms:** macOS, Linux
**Dependencies:** `node-development`
**Packages:**

- **NPM:** `create-react-app`, `create-next-app`, `eslint-plugin-react`, `eslint-plugin-react-hooks`
- **VS Code:** `dsznajder.es7-react-js-snippets`, `formulahendry.auto-rename-tag`

---

## rust-development

**Description:** Cargo extensions, debugging helpers, and VS Code integration layered on rust-runtime.
**Platforms:** macOS, Linux
**Dependencies:** `rust-runtime`
**Packages:**

- **Cargo:** `cargo-watch`, `cargo-edit`, `cargo-expand`, `cargo-outdated`, `cargo-audit`, `cargo-deny`
- **VS Code:** `rust-lang.rust-analyzer`
  **Configuration:**
- **Scripts:** `cleanup.sh` (Cleans Cargo cache).

---

## rust-runtime

**Description:** Rust runtime managed by mise.
**Platforms:** macOS, Linux
**Dependencies:** `tool-installers`
**Packages:**

- **Mise:** `rust@stable`

---

## shell-development

**Description:** Shell scripting tools including linting, formatting, and language server support.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`, `node-development`
**Packages:**

- **Homebrew:** `powershell`
- **VS Code:** `mads-hartmann.bash-ide-vscode`

---

## shell-essential

**Description:** Essential shell tools and development foundation for all environments. Includes git, bash/zsh, file navigation tools, and system monitoring utilities.
**Platforms:** macOS, Linux
**Packages:**

- **APK:** `curl`, `wget`, `git`, `git-lfs`, `bash`, `zsh`, `coreutils`, `direnv`, `bat`, `fzf`, `ripgrep`, `zoxide`, `htop`, `findutils`, `watch`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship`
- **APT:** (Similar comprehensive list + `apt-transport-https`, `ca-certificates`, `gnupg`)
- **DNF:** (Similar comprehensive list + `eza`, `glow`, `procps` equivalent)
- **Homebrew:** (Similar comprehensive list)
- **Pacman:** (Similar comprehensive list)
  **Configuration:**
- **Symlinks:** `zsh` configs, `starship.toml`, `eza` config, `.gitconfig`, `config.yaml`.
- **Scripts:** 
  - `setup.sh` (Oh My Zsh, Tmux TPM)
  - `init.sh` (Shell plugins, FZF with fd/bat integration, zoxide, starship)
  - `env.sh` (Environment variables: FZF paths, NPM config, pipx paths, EDITOR/VISUAL/GIT_EDITOR)
  - `cleanup.sh`
- **Features:**
  - Sets `EDITOR`, `VISUAL`, and `GIT_EDITOR` to `nvim` when available
  - Configures FZF to use `fd` for file/directory searching (respects `.gitignore`)
  - Enables bat-powered previews for FZF file selection (`Ctrl+T`)
  - Enables eza-powered directory tree previews (`Alt+C`)
  - Terminal title management with hooks for showing current directory
- **Starship Prompt Configuration:**
  - Optimized with 3-second command timeout for responsiveness
  - Optional "cockpit features" (battery, memory) disabled by default (use tmux status bar instead)
  - Focused on development context: git status, language versions, execution time
  - Streamlined format string removes redundant disabled modules

---

## terminal-apps

**Description:** Terminal emulator applications and configurations (Ghostty, Alacritty).
**Platforms:** macOS
**Dependencies:** `desktop-essential`
**Packages:**

- **Homebrew:** `ghostty`
  **Configuration:**
- **Config:** `alacritty/alacritty.toml`, `ghostty/config`
- **Symlinks:** Links `alacritty.toml` to `~/.config/alacritty/alacritty.toml`, `ghostty/config` to `~/.config/ghostty/config`.
- **Ghostty Features:**
  - Full shell integration (cursor, sudo, title features)
  - 50,000 line scrollback buffer (matching tmux)
  - Comprehensive clipboard settings
  - Window padding and state persistence
  - macOS-specific optimizations
  - Complete keybinding configuration
  - Theme support via auto-generation from `themes.yaml`

---

## tool-installers

**Description:** Core tool installer infrastructure including mise (polyglot version manager), pipx (Python tool installer), and cargo-binstall (Rust binary installer).
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **Homebrew:** `mise`, `pipx`, `cargo-binstall`
- **APT:** `python3-pip`, `pipx`
- **DNF:** `python3-pip`, `pipx`
- **Pacman:** `python-pip`, `python-pipx`
- **APK:** `py3-pip`, `py3-pipx`

**Environment Variables:**
- `PIPX_HOME`: Set to `$HOME/.local/pipx`
- `PIPX_BIN_DIR`: Set to `$HOME/.local/bin`

**PATH Additions:**
- `$HOME/.local/bin` (mise shims and pipx binaries)
- `$HOME/.cargo/bin` (cargo installed tools)

**Initialization:**
- Activates mise for current shell (zsh/bash)
- Enables mise shims for all installed runtimes

**Note:** This component is a dependency for all `*-runtime` components and must be installed first.

---

## tmux

**Description:** Terminal multiplexer for advanced terminal session management with clipboard integration, vim-aware navigation, and system monitoring.
**Platforms:** macOS, Linux
**Dependencies:** `shell-essential`
**Packages:**

- **APK:** `tmux`
- **APT:** `tmux`
- **DNF:** `tmux`
- **Homebrew:** `tmux`
- **Pacman:** `tmux`
  **Configuration:**
- **Config:** `tmux/.tmux.conf`
- **Symlinks:** Links `.tmux.conf` to `~/.tmux.conf`.
- **Plugins:** TPM, catppuccin theme, tmux-yank, tmux-resurrect, tmux-continuum, tmux-fingers, tmux-open, tmux-fzf
- **Status Bar Monitoring Scripts:**
  - `scripts/tmux-cpu`: System-wide CPU usage monitoring
  - `scripts/tmux-memory`: Active memory usage display
  - `scripts/tmux-battery`: Battery status with charging indicators
  - `scripts/tmux-weather`: Weather data via wttr.in (15-minute cache)
  - `scripts/generate-theme-tmux`: Generates themed status bar configuration
- **Features:**
  - **Vim-Aware Pane Navigation**: Seamless `C-h/j/k/l` navigation between vim windows and tmux panes
  - **System Monitoring**: macOS-style status bar with CPU, memory, battery, weather, date, and time
  - **Performance**: 50,000 line history buffer, RGB color support, undercurl
  - **Modern Clipboard**: Direct `pbcopy`/`pbpaste` integration (removed outdated `reattach-to-user-namespace`)
  - **Productivity Keybindings:**
    - `prefix + |/−`: Intuitive pane splitting
    - `prefix + >/<`: Pane swapping
    - `prefix + S`: Toggle status bar
    - `prefix + F`: tmux-fingers (fast link/path copying)
    - `prefix + o`: tmux-open (open files/URLs)
    - `prefix + C-f`: tmux-fzf (fuzzy finder)
    - `M-j/k`: Session navigation
    - `C-S-Left/Right`: Window movement
    - `Alt+1` through `Alt+9`: Quick window selection
    - `Alt+H/L`: Window navigation
  - **Copy Mode Enhancements:**
    - Vi-style visual selection (`v`, `y`, `Enter`)
    - `C-u/d`: Half-page scrolling
  - **Theme Support:** Auto-generation from `themes.yaml` via component scripts
  - Terminal title passthrough from nested applications
  - Mouse support for scrolling and pane selection

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
**Dependencies:** `node-development`
**Packages:**

- **NPM:** `sass`, `tailwindcss`, `lighthouse`, `netlify-cli`
- **VS Code:** `formulahendry.auto-close-tag`, `ritwickdey.LiveServer`
