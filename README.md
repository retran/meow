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

A comprehensive dotfiles management system that automates the tedious task of configuring a new machine by applying predefined setups called "presets." Instead of spending hours installing packages and tweaking configs, just pick a preset and you're ready to code. Part of the `project meow` ecosystem, including [`Meowvim`](https://github.com/retran/meowvim) for Neovim configuration.

## 🖼️ Screenshots

<div align="center">

<img src="assets/screenshot.png" alt="meow shell" width="800">

</div>

## 📋 Table of Contents

- [🖼️ Screenshots](#️-screenshots)
- [🌟 Key Features](#-key-features)
- [✨ Features](#-features)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Installation](#-installation)
- [⚡ Quick Start](#-quick-start)
- [🧩 Components](#-components)
- [🔧 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)

## 🌟 Key Features

- **🎯 Two Main Presets**: personal and corporate
- **📦 Multi-Package Manager**: Homebrew, pipx, npm, Go packages, and Mac App Store
- **🔧 Pre-configured Environments**: Go, .NET, Kotlin, Godot, JavaScript, React, and more
- **🔗 Automatic Dotfile Linking**: Seamless configuration deployment
- **🧩 Mix and Match Components**: Custom setups for specific needs
- **⚡ One-Command Setup**: Single script installation and updates
- **🌐 macOS Support**: Designed specifically for macOS systems

## ✨ Features

`meow` provides a comprehensive development environment setup with these key capabilities:

### 🎯 Preset System

- **Personal Preset**: Full development setup with all tools and customizations
- **Corporate Preset**: Work-focused Go development environment

### 🔧 Development Environments

- **Go Development**: Complete environment with language server, debugger, and tools
- **JavaScript/TypeScript**: Node.js tools, language servers, and formatters
- **Kotlin Development**: Kotlin environment and tooling
- **.NET Development**: .NET tools and SDK
- **React Development**: React-specific tooling extending JavaScript
- **Web Development**: CSS frameworks, build tools, and HTTP testing
- **Game Development**: Tools and engines including Godot
- **Markdown**: Technical writing with linting and presentation tools

### 🐾 User Experience

- **Automatic Configuration**: Seamless dotfile linking and setup
- **One-Command Installation**: Simple script-based deployment
- **Modular Components**: Mix and match for custom setups
- **Dependency Resolution**: Automatic component dependency management

## 📋 Prerequisites

Before installing `meow`, ensure you have the following:

### Required

- **Operating System**: macOS
- **Shell**: Bash 3.2+ (default on macOS) or Zsh
- **Git**: For cloning the repository and version control integration
- **Internet Connection**: For downloading packages and tools

### Bash Compatibility

`meow` is designed to work with the default bash 3.2 that ships with macOS, avoiding the chicken-and-egg problem where you need a newer bash to install a newer bash. The scripts automatically detect your bash version and run in compatibility mode when needed.

- **✅ Fully supported**: bash 3.2+ (macOS default)
- **🚀 Enhanced experience**: bash 4.0+ (after Homebrew installation)
- **📦 Modern features**: bash 5.0+ (latest features and performance)

## 🚀 Installation

For a complete setup with all submodules (including `Meowvim`):

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow
cd ~/.meow

# Install your preferred preset
./bin/install.sh PRESET_NAME
```

## ⚡ Quick Start

After installation, follow these steps to get started:

### 1. Choose Your Preset

Based on your needs:

- **New personal machine**: Use `personal` preset
- **Work environment**: Use `corporate` preset

### 2. One-Command Setup

```bash
# Personal environment
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh personal

# Corporate environment
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh corporate
```

### 3. Enjoy Your Setup

After installation:

- All development tools will be available
- Configurations are automatically linked

### 4. Keep It Updated

```bash
# Update installed preset
./bin/update.sh
```

## 🧩 Components

`meow` uses a modular component system where each component can depend on others, creating a layered architecture for development environments:

### Foundation Components

- **🐚 shell-essential** - Essential shell tools component (Git, Tmux, Starship, Neovim)
- **🖥️ desktop-essential** - GUI foundation component for macOS desktop environment
- **🛠️ core-development** - Core development tools shared across all programming environments (depends on shell-essential)
- **🎨 fonts** - Essential programming and design fonts

### Programming Languages

- **🐹 go-development** - Complete Go development environment with language server, debugger, linters, and build tools
- **⚡ javascript** - JavaScript/TypeScript development with Node.js tools, language servers, and formatters
- **🗾 kotlin-development** - Kotlin development environment and tools
- **🦄 dotnet-development** - .NET development tools and SDK

### Frontend & Web Development

- **⚛️ react** - React development framework extending JavaScript with React-specific tooling
- **🌐 web** - Advanced web development with CSS frameworks, build tools, deployment utilities, and HTTP testing (extends React)

### Specialized Development

- **🎮 game-development** - Game development tools including Godot and tools for Pico-8/Picotron
- **📝 markdown** - Technical writing with linting, spell checking, presentation tools, and terminal rendering

### Communication & Productivity

- **💼 corporate-communication** - Professional communication tools for work environments
- **👥 personal-communication** - Personal messaging and social applications
- **📋 productivity** - Set of productivity tools

### Entertainment & Media

- **🎮 gaming** - Gaming platforms and applications
- **🎨 media** - Media editing and graphics tools

### Package Manager Support

Components support multiple package managers depending on their needs:

- **brew**
- **npm**
- **pipx**
- **gopm**
- **mas**
- **VS Code extensions**

Components automatically resolve dependencies - for example, `react` includes `javascript`, which includes `core-development`, which includes `shell-essential`.

## 🔧 Troubleshooting

### Common Issues

#### Installation Fails

```bash
# Check if Git is installed
git --version

# Ensure submodules are properly initialized
cd ~/.meow
git submodule init
git submodule update --recursive

# Try installing again
./bin/install.sh PRESET_NAME
```

#### Package Manager Issues

```bash
# For Homebrew issues on macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For npm issues
npm cache clean --force
npm install -g npm@latest

# For pipx issues
python -m pip install --upgrade pipx
pipx ensurepath
```

#### `Meowvim` Configuration Not Working

```bash
# Check if Meowvim submodule is properly initialized
cd ~/.meow
git submodule status

# If not initialized, run:
git submodule init
git submodule update

# Check Neovim installation
nvim --version
```

#### Permission Issues

```bash
# Fix ownership issues
sudo chown -R $(whoami) ~/.meow

# Fix script permissions
chmod +x ~/.meow/bin/*.sh
```

### Getting Help

- Check the [issues page](https://github.com/retran/meow/issues)
- Review preset configurations in `presets/` directory
- Examine component definitions in `presets/components/`
- Check package definitions in `packages/` directory

## 🤝 Contributing

Contributions are welcome to help improve `meow`! Here's how you can help:

### Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest new features or presets
- 📝 Improve documentation
- 🔧 Submit code improvements
- 🎨 Enhance configurations
- 📦 Add new package integrations

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

`meow` builds on the excellent work of the open-source community and various development tools.

- [Homebrew](https://brew.sh/) - The missing package manager for macOS
- [zsh](https://zsh.sourceforge.io/) - Z shell
- [Oh My Zsh](https://ohmyz.sh/) - Zsh configuration framework
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [git](https://git-scm.com/) - Version control system
- [Starship](https://starship.rs/) - Cross-shell prompt
- [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor
- [Neovide](https://neovide.dev/) - Neovim GUI client
- [Visual Studio Code](https://code.visualstudio.com/) - Code editor
- [Ghostty](https://ghostty.org/) - Terminal emulator
- [Node.js](https://nodejs.org/) - JavaScript runtime
- [Go](https://golang.org/) - Programming language
- [Python](https://www.python.org/) - Programming language
- [mas](https://github.com/mas-cli/mas) - Mac App Store command line interface
- [Raycast](https://raycast.com/) - Productivity tool for macOS
- [Hammerspoon](https://www.hammerspoon.org/) - macOS automation tool
- [fzf](https://github.com/junegunn/fzf) - Command-line fuzzy finder
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Line-oriented search tool
- [fd](https://github.com/sharkdp/fd) - Simple, fast and user-friendly alternative to find
- [jq](https://stedolan.github.io/jq/) - Command-line JSON processor
- [yq](https://github.com/mikefarah/yq) - Command-line YAML processor
- [task](https://taskfile.dev/) - Task runner / build tool
- [pandoc](https://pandoc.org/) - Universal document converter
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) - Typeface for developers
- [Nerd Fonts](https://www.nerdfonts.com/) - Iconic font aggregator
- [Tokyo Night](https://github.com/tokyo-night) - Clean, dark theme

and many other amazing open-source projects that make development a joy

### Author

`meow` is developed by Andrew Vasilyev with help from GitHub Copilot and feline assistants Sonya Blade, Mila, and Marcus Fenix.

---

<div align="center">

**Happy coding with `project meow`! 🐱**

Made with ❤️ by Andrew Vasilyev and feline assistants

[Report Bug](https://github.com/retran/meow/issues) · [Request Feature](https://github.com/retran/meow/issues) · [Contribute](https://github.com/retran/meow/pulls)

</div>
