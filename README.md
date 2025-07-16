# 🐱 meow

A powerful, modular dotfiles management system that helps developers quickly set up and maintain their development environment across different machines.

## 🚀 What is meow?

meow is a Shell-based dotfiles management system that automates the setup of your development environment using predefined configurations called "presets." Whether you're setting up a new machine, switching between work and personal configurations, or maintaining consistency across multiple devices, meow simplifies the process with just a single command.

**Problem it solves:** Setting up a development environment from scratch is time-consuming and error-prone. meow eliminates the hassle by providing battle-tested configurations that can be applied instantly, ensuring consistency and saving hours of manual setup time.

## ✨ Features

- **🎯 Multiple Presets**: Choose from personal, corporate, shell-essential, or desktop-essential configurations
- **📦 Package Manager Integration**: Automatic package installation via Homebrew, pipx, Mac App Store, and more
- **🔧 Development Environment Setup**: Pre-configured setups for Go, .NET, Kotlin, and game development
- **🎨 Terminal Customization**: Beautiful ASCII art greetings and customized shell experience
- **🔗 Symbolic Link Management**: Automatic dotfile linking and configuration deployment
- **📱 Cross-Platform Support**: Optimized for macOS with shell environment compatibility
- **🧩 Modular Components**: Mix and match components to create custom configurations
- **🔄 Easy Updates**: Keep your packages and configurations up-to-date with simple commands

## 📋 Prerequisites

- **Operating System**: macOS (primary), Linux/Unix systems (shell-essential preset)
- **Shell**: Bash or Zsh
- **Package Manager**: Homebrew (for macOS package installations)
- **Git**: For cloning the repository and version control integration

## 🛠️ Installation

### Quick Install

Clone the repository and run the installer with your preferred preset:

```bash
# Clone the repository
git clone https://github.com/retran/meow.git ~/.meow

# Navigate to the directory
cd ~/.meow

# Install with your preferred preset
./bin/install.sh PRESET_NAME
```

### Available Presets

Choose the preset that best fits your needs:

#### 🏠 Personal (`personal`)
Complete setup for personal development machines with all development tools and entertainment packages.

```bash
./bin/install.sh personal
```

**Includes:** Shell essentials + Desktop essentials + All development languages (Go, .NET, Kotlin) + Gaming + Media/Graphics + Communication tools

#### 🏢 Corporate (`corporate`)
Work-focused setup optimized for corporate environments with Go development and productivity tools.

```bash
./bin/install.sh corporate
```

**Includes:** Shell essentials + Desktop essentials + Go development + Corporate communication + Productivity tools

#### 🐚 Shell Essential (`shell-essential`)
Minimal setup perfect for servers or headless systems with essential shell tools only.

```bash
./bin/install.sh shell-essential
```

**Includes:** Git + Tmux + Starship prompt + Neovim + Essential shell utilities

#### 🖥️ Desktop Essential (`desktop-essential`)
Foundation for GUI-based systems without specific development language setups.

```bash
./bin/install.sh desktop-essential
```

**Includes:** Shell essentials + GUI applications + Basic desktop productivity tools

## 📖 Usage

### Basic Commands

```bash
# Install a preset
./bin/install.sh personal

# Update packages for all installed presets
./bin/update.sh

# Update packages for a specific preset
./bin/update.sh corporate

# Get help
./bin/install.sh --help
./bin/update.sh --help
```

### Example Workflows

**Setting up a new personal development machine:**
```bash
git clone https://github.com/retran/meow.git ~/.meow
cd ~/.meow
./bin/install.sh personal
```

**Setting up a work laptop:**
```bash
git clone https://github.com/retran/meow.git ~/.meow
cd ~/.meow
./bin/install.sh corporate
```

**Setting up a remote server:**
```bash
git clone https://github.com/retran/meow.git ~/.meow
cd ~/.meow
./bin/install.sh shell-essential
```

**Keeping packages updated:**
```bash
cd ~/.meow
./bin/update.sh  # Updates all installed presets
# or
./bin/update.sh personal  # Updates specific preset
```

### Environment Variables

meow respects XDG Base Directory specifications and uses these environment variables:

- `DOTFILES_DIR`: Location of the meow installation (default: `$HOME/.meow`)
- `XDG_CONFIG_HOME`: Configuration directory (default: `$HOME/.config`)
- `XDG_CACHE_HOME`: Cache directory (default: `$HOME/.cache`)
- `XDG_DATA_HOME`: Data directory (default: `$HOME/.local/share`)

## 🎨 What Gets Installed

### Shell Essential Preset
- **Git**: Version control with optimized configuration
- **Tmux**: Terminal multiplexer with custom key bindings
- **Starship**: Cross-shell prompt with beautiful themes
- **Neovim**: Modern Vim-based editor with configurations
- **Essential shell utilities**: Core command-line tools

### Desktop Essential Preset
- All shell essential components
- GUI applications for desktop productivity
- Basic development tools

### Corporate Preset
- All desktop essential components
- **Go development environment**: Complete Go toolchain
- **Corporate communication**: Slack, Zoom, and work-focused tools
- **Productivity suite**: Tools optimized for work environments

### Personal Preset
- All desktop essential components
- **Multi-language development**: Go, .NET, Kotlin support
- **Game development**: Unity, game development tools
- **Gaming**: Entertainment and gaming applications
- **Media & Graphics**: Creative and media editing tools
- **Communication**: Both personal and work communication tools

## 📚 Documentation

- **Configuration Files**: Located in `config/` directory
- **Component Documentation**: Each component in `presets/components/` has its own configuration
- **Package Lists**: Package definitions are in the `packages/` directory
- **Library Functions**: Core functionality documented in `lib/` directory

For detailed configuration options, explore the following directories:
- `config/` - Application-specific configurations
- `presets/` - Preset definitions and component dependencies
- `packages/` - Package manager integrations

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Reporting Issues
- Use GitHub Issues to report bugs or request features
- Provide detailed information about your system and the issue
- Include relevant error messages and steps to reproduce

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/meow.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Test your changes with different presets
5. Submit a pull request

### Adding New Components
1. Create component files in `presets/components/`
2. Define package dependencies in `packages/`
3. Add configuration files in `config/` if needed
4. Test the component with existing presets
5. Update documentation

### Code Style
- Follow existing shell scripting conventions
- Use meaningful variable names and comments
- Test on macOS and ensure compatibility
- Maintain modular structure

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright (c) 2025 Andrew Vasilyev**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

## 🙏 Acknowledgments

- Inspired by the dotfiles community and best practices
- Built with modularity and user experience in mind
- Thanks to all contributors and users who help improve meow

---

**Made with 🐱 by the meow team**