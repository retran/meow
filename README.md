# 🐱 meow

> The purr-fect dotfiles management system that sets up your development environment with a single meow.

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


`meow` was born from the desire to eliminate the repetitive and time-consuming task of setting up a development environment from scratch. Instead of manually installing packages, cloning repositories, and symlinking configuration files for hours, **`meow` lets you do it all with a single command**.

It uses a powerful **preset system** to deploy a complete, tailored environment, so you can get straight to coding. Whether you're setting up a new personal laptop, a corporate workstation, or a disposable development container, `meow` has a *purr-fect* setup for you.

## 📋 Table of Contents
- [🖼️ Screenshots](#screenshots)
- [✨ Features](#features)
- [📋 Prerequisites](#prerequisites)
- [🚀 Getting Started](#getting-started)
- [💡 Usage](#usage)
- [🎨 Customization](#customization)
- [🧩 Components](#components)
- [🔧 Troubleshooting](#troubleshooting)
- [🤝 Contributing](#contributing)
- [📄 License](#license)
- [🙏 Acknowledgments](#acknowledgments)

---

## 🖼️ Screenshots

<div align="center">

<img src="assets/screenshots/screenshot_login.png" alt="login"   width="800">
<img src="assets/screenshots/screenshot_update.png" alt="update" width="800">
<img src="assets/screenshots/screenshot_neovim.png" alt="vim"    width="800">

</div>

---

## ✨ Features

`meow` provides a comprehensive development-environment setup with these key capabilities.

### 🎯 Preset System

| Preset | Description | File |
| ------ | ----------- | ---- |
| **Personal** | Environment focused on development of pet projects and entertainment | `personal.yaml` |
| **Corporate** | Work-focused Go development environment | `corporate.yaml` |
| **Litterbox Essential** | Minimal base setup, ideal for containers | `litterbox-essential.yaml` |
| **Litterbox Go** | Container-friendly Go environment | `litterbox-go.yaml` |

### 🔧 Development Environments

- **Go Development** – language server, debugger, and tooling
- **JavaScript/TypeScript** – Node.js tool-chain, language servers, formatters
- **Kotlin Development** – Kotlin compiler and tooling
- **.NET Development** – .NET SDK and CLI tools
- **React Development** – React-specific extensions to JS setup
- **Web Development** – CSS frameworks, build tools, HTTP testing
- **Game Development** – tooling and engines, including Godot
- **Markdown** – technical-writing helpers, linters, presenters

### 🐾 User Experience

- **Automatic Configuration** – dotfile linking and application setup
- **One-Command Installation** – simple script-based deployment
- **Modular Components** – mix-and-match to build a custom setup
- **Dependency Resolution** – automatic component-dependency handling

---

## 📋 Prerequisites

### Required

| Requirement | Supported |
| ----------- | ---------- |
| **OS** | macOS · Alpine · Debian/Ubuntu · Arch |
| **Shell** | Bash ≥ 3.2 |
| **Internet** | Needed to download packages & tools |
| **Git** | For cloning the repository and submodules |

> **Bash compatibility:** `meow` works with the default Bash 3.2 that ships with macOS, avoiding the chicken-and-egg problem of needing a newer shell to install a newer shell.

---

## 🚀 Getting Started

1. **Choose your preset** – e.g. `personal`, `corporate`.
2. **Run the one-command setup** – copy/paste the snippet below.
3. **Restart your shell** – open a new terminal window.

### One-Command Setup — Personal

```bash
git clone --recursive https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh personal
```

### One-Command Setup — Corporate

```bash
git clone --recursive https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh corporate
```

---

## 💡 Usage

Your environment is ready to use as soon as the installer finishes.

### Keeping It Updated

```bash
cd ~/.meow
./bin/update.sh
```

The updater **pulls the latest changes** and reapplies the installation logic for your preset, keeping packages and dependencies fresh.

---

## 🎨 Customization

While `meow` ships with handy presets, its true power is modularity.

### Creating a Custom Preset

1. Create `presets/my-setup.yaml`.
2. List your desired components.
3. Install with:

```bash
cd ~/.meow
./bin/install.sh my-setup
```

---

## 🧩 Components

`meow` uses a **layered component system**; each component can depend on others.

### Foundation Components

* **🐚 `shell-essential`** – Git, Tmux, Starship, Neovim, fzf, ripgrep, zoxide
* **🔧 `shell-development`** – shellcheck, shfmt, bash-language-server, yamllint
* **🎨 `fonts`** – JetBrains Mono, Nerd Fonts
* **🖥️ `desktop-essential`** – GUI foundation (fonts, browser, terminal, VS Code)
* **🛠️ `core-development`** – GitHub CLI, LSPs, formatters, go-task
* **📦 `node`** – Node.js runtime & npm
* **🐍 `pipx`** – Python app isolation & launch

### Development Environments

* **🐳 `docker-cli`** – Docker CLI tooling
* **🐋 `docker-desktop`** – Docker Desktop (macOS)
* **🐹 `go-development`** – gopls, delve, staticcheck, air, templ, swag
* **⚡ `js-development`** – JS/TS tool-chain
* **⚛️ `react-development`** – React extensions to JS setup
* **🌐 `web-development`** – advanced web stack (extends React)
* **🦀 `rust-development`** – Rust compiler & tooling
* **🗾 `kotlin-development`** – Kotlin tool-chain
* **🦄 `dotnet-development`** – .NET SDK & tools
* **🌙 `lua-development`** – Lua runtime & tools
* **🐍 `python-development`** – Python dev-stack
* **🎮 `game-development`** – development tools for Godot
* **📝 `markdown`** – writing & presentation helpers

### Communication & Productivity

* **💼 `corporate-communication`** – professional comms tools
* **👥 `personal-communication`** – personal messaging apps
* **📋 `productivity`** – productivity & workflow helpers

### Entertainment & Media

* **🎮 `gaming`** – Steam, NVIDIA GeForce Now
* **🎨 `media`** – OBS

---

## 🔧 Troubleshooting

### Installation Fails

```bash
# Check if Git is installed
git --version

# Ensure submodules are initialised
cd ~/.meow
git submodule update --init --recursive

# Retry installation
./bin/install.sh <PRESET_NAME>
```

### Package-Manager Issues

```bash
# Homebrew (macOS)
brew doctor

# npm
npm cache clean --force
npm install -g npm@latest

# pipx
python3 -m pip install --user --upgrade pipx
pipx ensurepath
```

### Getting Help

1. Check the **[Issues](https://github.com/retran/meow/issues)** page.
2. Review preset files in `presets/`.
3. Examine component definitions in `presets/components/`.

---

## 🤝 Contributing

Contributions are welcome to help improve `meow`! Here's how you can help:

### Ways to Contribute

* 🐛 Report bugs & issues
* 💡 Suggest features or presets
* 📝 Improve documentation
* 🔧 Submit pull requests
* 🎨 Enhance configurations
* 📦 Add new package integrations

---

## 📄 License

Licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

## 🙏 Acknowledgments

`meow` builds on the excellent work of the open-source community. Huge thanks to:

* [Homebrew](https://brew.sh/) • [Git](https://git-scm.com/) • [GitHub CLI](https://cli.github.com/)
* [tmux](https://github.com/tmux/tmux) • [Starship](https://starship.rs/) • [Neovim](https://neovim.io/)
* [Visual Studio Code](https://code.visualstudio.com/) • [fzf](https://github.com/junegunn/fzf)
* [ripgrep](https://github.com/BurntSushi/ripgrep) • [zoxide](https://github.com/ajeetdsouza/zoxide)
* [Go](https://golang.org/) • [Node.js](https://nodejs.org/) • [Rust](https://www.rust-lang.org/)
* [Raycast](https://raycast.com/) • [Hammerspoon](https://www.hammerspoon.org/)
* [Nerd Fonts](https://www.nerdfonts.com/)
* …and the many other projects that make development enjoyable.

---

### Author

`meow` is developed by Andrew Vasilyev with help from GitHub Copilot and feline assistants Sonya Blade, Mila, and Marcus Fenix.

---

<div align="center">

**Happy coding with `project meow`! 🐱**

Made with ❤️ by Andrew Vasilyev and feline assistants

[Report Bug](https://github.com/retran/meow/issues) · [Request Feature](https://github.com/retran/meow/issues) · [Contribute](https://github.com/retran/meow/pulls)

</div>
