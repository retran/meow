# 🐱 meow

A dotfiles management system that sets up your development environment with a single command.

meow automates the tedious task of configuring a new machine by applying predefined setups called "presets." Instead of spending hours installing packages and tweaking configs, just pick a preset and you're ready to code.

## ✨ Features

- 🎯 Four main presets: personal, corporate, shell-essential, desktop-essential
- 📦 Package management via Homebrew, pipx, npm, Go packages, and Mac App Store
- 🔧 Pre-configured development environments (Go, .NET, Kotlin, Godot, JavaScript, React, ...)
- 🐾 Cat-themed terminal greetings and customizations
- 🔗 Automatic dotfile linking
- 🧩 Mix and match components for custom setups

## 📋 Prerequisites

- **Operating System**: macOS (primary), Linux/Unix systems (shell-essential preset)
- **Shell**: Bash or Zsh
- **Git**: For cloning the repository and version control integration

## 🛠️ Installation

```bash
# Clone and install
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow
cd ~/.meow
./bin/install.sh PRESET_NAME
```

If you've already cloned without submodules:
```bash
git submodule init
git submodule update
```

### Presets

**🏠 personal** - Complete development setup with all the bells and whistles
```bash
./bin/install.sh personal
```

**🏢 corporate** - Work-focused Go development environment
```bash
./bin/install.sh corporate
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

```bash
# Update packages
./bin/update.sh                    # All presets
./bin/update.sh corporate          # Specific preset

# Get help
./bin/install.sh --help
```

### Common workflows

**New personal machine:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh personal
```

**Remote server:**
```bash
git clone --recurse-submodules https://github.com/retran/meow.git ~/.meow && cd ~/.meow && ./bin/install.sh shell-essential
```

## 📚 Documentation

- `config/` - Application configurations
- `config/nvim/` - Custom Neovim configuration (meowvim submodule)
- `presets/` - Preset definitions and components
- `packages/` - Package manager integrations

## 🤝 Contributing

Found a bug? Want to add a new preset? Here's how to help:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Test your changes with different presets
4. Submit a pull request

### Adding components
1. Create component files in `presets/components/`
2. Define packages in `packages/`
3. Add configs in `config/` if needed
4. Test and update docs

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

**🐾 Purr-fected by Andrew Vasilyev with help from feline assistants Sonya, Mila, and Marcus Fenix**
