# 🐱 meow

> The purr-fect dotfiles management system that sets up your development environment with a single command.

<div align="center">

![Zsh](https://img.shields.io/badge/zsh-%23019733.svg?style=for-the-badge&logo=zsh&logoColor=white)
![Tmux](https://img.shields.io/badge/tmux-%23019733.svg?style=for-the-badge&logo=tmux&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)
![GitHub stars](https://img.shields.io/github/stars/retran/meow?style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/retran/meow?style=for-the-badge)

</div>

<div align="center">
<img src="assets/icon_small.png" alt="Meow Logo" width="200">
<br>
<strong>meow - Purr-fect Development Environment</strong>
</div>

A comprehensive dotfiles management system that automates the tedious task of configuring a new machine by applying predefined setups called "presets." Instead of spending hours installing packages and tweaking configs, just pick a preset and you're ready to code. Part of the meow ecosystem, including [MeowVim](https://github.com/retran/meowvim) for Neovim configuration.

## 🌟 Key Features

- **🎯 Four Main Presets**: personal, corporate, shell-essential, desktop-essential
- **📦 Multi-Package Manager**: Homebrew, pipx, npm, Go packages, and Mac App Store
- **🔧 Pre-configured Environments**: Go, .NET, Kotlin, Godot, JavaScript, React, and more
- **🐾 Cat-themed Customizations**: Terminal greetings and personalized touches
- **🔗 Automatic Dotfile Linking**: Seamless configuration deployment
- **🧩 Mix and Match Components**: Custom setups for specific needs
- **⚡ One-Command Setup**: Single script installation and updates
- **🌐 Cross-Platform Support**: macOS (primary), Linux/Unix systems

## 📋 Table of Contents

- [✨ Features](#-features)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Installation](#-installation)
- [⚡ Quick Start](#-quick-start)
- [📖 Usage](#-usage)
- [🧩 Components](#-components)
- [📚 Documentation](#-documentation)
- [🔧 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)

## ✨ Features

meow provides a comprehensive development environment setup with these key capabilities:

### 🎯 Preset System
- **Four Main Presets**: Complete development configurations for different use cases
- **Personal Preset**: Full development setup with all tools and customizations
- **Corporate Preset**: Work-focused Go development environment
- **Shell-Essential**: Core terminal tools for any system
- **Desktop-Essential**: GUI foundation for macOS applications

### 📦 Package Management
- **Homebrew**: Native macOS applications and system tools
- **npm**: JavaScript/Node.js packages and development tools
- **pipx**: Python command-line applications in isolated environments
- **Go Packages**: Development tools via `go install`
- **VS Code Extensions**: Enhanced development experience
- **Mac App Store**: Commercial applications and utilities

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
- **Cat-themed Branding**: MeowVim ASCII art and terminal greetings
- **Automatic Configuration**: Seamless dotfile linking and setup
- **One-Command Installation**: Simple script-based deployment
- **Modular Components**: Mix and match for custom setups
- **Dependency Resolution**: Automatic component dependency management

## 📋 Prerequisites

Before installing meow, ensure you have the following:

### Required
- **Operating System**: macOS (primary support), Linux/Unix systems (shell-essential preset)
- **Shell**: Bash or Zsh
- **Git**: For cloning the repository and version control integration

### Recommended
- **Homebrew**: Package manager for macOS (installed automatically if missing)
- **Internet Connection**: For downloading packages and tools
- **Terminal**: With true color support for optimal experience

### Optional
- **Node.js**: For JavaScript/TypeScript development components
- **Python**: For Python development tools and pipx packages
- **Go**: For Go development environment
- **VS Code**: For editor extensions and integrations

## 🚀 Installation

### Option 1: Fresh Installation

For a complete setup with all submodules (including MeowVim):

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow
cd ~/.meow

# Install your preferred preset
./bin/install.sh PRESET_NAME
```

### Option 2: Existing Repository

If you've already cloned without submodules:

```bash
# Navigate to your existing clone
cd ~/.meow

# Initialize and update submodules
git submodule init
git submodule update

# Install your preferred preset
./bin/install.sh PRESET_NAME
```

### Available Presets

**🏠 Personal** - Complete development setup with all tools and customizations
```bash
./bin/install.sh personal
```

**🏢 Corporate** - Work-focused Go development environment
```bash
./bin/install.sh corporate
```

**🐚 Shell-Essential** - Core terminal tools for any system
```bash
./bin/install.sh shell-essential
```

**🖥️ Desktop-Essential** - GUI foundation for macOS applications
```bash
./bin/install.sh desktop-essential
```

## ⚡ Quick Start

After installation, follow these steps to get started:

### 1. Choose Your Preset
Based on your needs:
- **New personal machine**: Use `personal` preset
- **Work environment**: Use `corporate` preset
- **Remote server**: Use `shell-essential` preset
- **GUI applications**: Use `desktop-essential` preset

### 2. One-Command Setup
```bash
# New personal machine
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh personal

# Remote server
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh shell-essential
```

### 3. Enjoy Your Setup
After installation:
- Your shell will display the new MeowVim ASCII art
- All development tools will be available
- Configurations are automatically linked
- MeowVim (if included) is ready to use

### 4. Keep It Updated
```bash
# Update all packages
./bin/update.sh

# Update specific preset
./bin/update.sh corporate
```

## 🧩 Components

meow uses a modular component system where each component can depend on others, creating a layered architecture for development environments:

### Foundation Components

- **🐚 shell-essential** - Essential shell tools installable on any system (Git, Tmux, Starship, Neovim)
- **🖥️ desktop-essential** - GUI foundation for macOS desktop applications  
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

- **🎮 game-development** - Game development tools and engines including Godot
- **📝 markdown** - Technical writing with linting, spell checking, presentation tools, and terminal rendering

### Communication & Productivity

- **💼 corporate-communication** - Professional communication tools for work environments
- **👥 personal-communication** - Personal messaging and social applications  
- **📋 productivity** - Productivity applications and organizational utilities

### Entertainment & Media

- **🎮 gaming** - Gaming platforms and applications
- **🎨 media** - Media editing and graphics tools

### Package Manager Support

Components support multiple package managers depending on their needs:
- **Homebrew**: Native macOS applications and system tools
- **npm**: JavaScript/Node.js packages and development tools  
- **pipx**: Python command-line applications installed in isolation
- **Go packages**: Go development tools installed via `go install`
- **VS Code**: Editor extensions for enhanced development experience
- **Mac App Store**: Commercial applications and utilities

Components automatically resolve dependencies - for example, `react` includes `javascript`, which includes `core-development`, which includes `shell-essential`.

## 📖 Usage

### Updating Your System

```bash
# Update all packages for all presets
./bin/update.sh

# Update packages for a specific preset
./bin/update.sh corporate

# Update packages for shell-essential preset
./bin/update.sh shell-essential
```

### Getting Help

```bash
# Get help for the install script
./bin/install.sh --help

# Get help for the update script
./bin/update.sh --help
```

### Common Workflows

**New personal machine:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh personal
```

**Work environment setup:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh corporate
```

**Remote server setup:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh shell-essential
```

**GUI applications only:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh desktop-essential
```

## 📚 Documentation

### File Structure
```
~/.meow/
├── bin/                  # Installation and update scripts
│   ├── install.sh       # Main installation script
│   └── update.sh        # Update script
├── config/              # Application configurations
│   ├── nvim/           # MeowVim Neovim configuration (submodule)
│   ├── tmux/           # Tmux configuration
│   └── zsh/            # Zsh configuration
├── presets/             # Preset definitions and components
│   ├── components/     # Individual component definitions
│   └── presets/        # Preset configurations
├── packages/            # Package manager integrations
│   ├── brew/           # Homebrew packages
│   ├── npm/            # npm packages
│   ├── pipx/           # pipx packages
│   └── go/             # Go packages
├── lib/                 # Library functions
│   ├── motd/           # Message of the day system
│   └── core/           # Core utilities
└── assets/             # Static assets
    ├── ascii/          # ASCII art files
    └── comments/       # Random comment collections
```

### Key Files
- **`config/nvim/`**: Custom Neovim configuration (MeowVim submodule)
- **`presets/`**: Preset definitions and component configurations
- **`packages/`**: Package manager integrations for different tools
- **`lib/motd/`**: Message of the day system with cat-themed greetings
- **`assets/ascii/`**: ASCII art files including MeowVim branding

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

#### MeowVim Not Working
```bash
# Check if MeowVim submodule is properly initialized
cd ~/.meow
git submodule status

# If not initialized, run:
git submodule init
git submodule update

# Check Neovim installation
nvim --version
```

#### ASCII Art Not Displaying
1. **Terminal Support**: Ensure your terminal supports true color
2. **Font Issues**: Install a Nerd Font for proper icon display
3. **Color Settings**: Check your terminal's color settings

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

Contributions are welcome to help improve meow! Here's how you can help:

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest new features or presets
- 📝 Improve documentation
- 🔧 Submit code improvements
- 🎨 Enhance configurations
- 📦 Add new package integrations

### Development Setup
```bash
# Fork the repository
git clone https://github.com/YOUR-USERNAME/meow.git ~/.meow-dev
cd ~/.meow-dev

# Initialize submodules
git submodule init
git submodule update --recursive

# Create a feature branch
git checkout -b feature/new-feature

# Make your changes and test thoroughly with different presets
./bin/install.sh shell-essential  # Test basic functionality
./bin/install.sh personal         # Test full installation

# Commit your changes
git commit -m "Add new feature"

# Push to your fork
git push origin feature/new-feature

# Create a Pull Request
```

### Adding New Components
1. **Create component files** in `presets/components/`
2. **Define packages** in `packages/` for each package manager
3. **Add configurations** in `config/` if needed
4. **Update presets** to include your component
5. **Test thoroughly** with different presets
6. **Update documentation** as needed

### Code Style
- Follow existing code patterns and structure
- Use meaningful variable names and comments
- Keep functions focused and small
- Test your changes with multiple presets
- Ensure backward compatibility

### Pull Request Guidelines
1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes with clear commit messages
4. Test thoroughly with different presets
5. Update documentation if needed
6. Submit a Pull Request with a clear description

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

meow builds on the excellent work of the open-source community and various development tools.

### Core Tools
- [Homebrew](https://brew.sh/) - The missing package manager for macOS
- [Zsh](https://zsh.sourceforge.io/) - Extended shell with advanced features
- [Tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [Git](https://git-scm.com/) - Version control system

### Development Environments
- [Go](https://golang.org/) - Programming language and tools
- [Node.js](https://nodejs.org/) - JavaScript runtime
- [Python](https://python.org/) - Programming language
- [.NET](https://dotnet.microsoft.com/) - Development platform

### Package Managers
- [npm](https://npmjs.com/) - Node.js package manager
- [pipx](https://pipxproject.github.io/pipx/) - Python application installer
- [VS Code](https://code.visualstudio.com/) - Code editor platform

### MeowVim Integration
- [MeowVim](https://github.com/retran/meowvim) - Neovim configuration system
- [Neovim](https://neovim.io/) - Extensible text editor
- [Lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager

### Author
meow is developed by Andrew Vasilyev with help from feline assistants Sonya, Mila, and Marcus Fenix.

---

<div align="center">

**Happy coding with meow! 🐱**

Made with ❤️ by Andrew Vasilyev and feline assistants

[Report Bug](https://github.com/retran/meow/issues) · [Request Feature](https://github.com/retran/meow/issues) · [Contribute](https://github.com/retran/meow/pulls)

</div>
