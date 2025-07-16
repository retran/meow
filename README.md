# 🐱 meow

A dotfiles management system that sets up your development environment with a single command.

meow automates the tedious task of configuring a new machine by applying predefined setups called "presets." Instead of spending hours installing packages and tweaking configs, just pick a preset and you're ready to code.

## ✨ Features

- 🎯 Eight presets: personal, corporate, shell-essential, desktop-essential, javascript, react, web, markdown
- 📦 Package management via Homebrew, pipx, npm, and Mac App Store
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

**🐚 shell-essential** - Minimal setup for servers (Git, Tmux, Starship, Neovim)
```bash
./bin/install.sh shell-essential
```

**🖥️ desktop-essential** - GUI foundation without specific dev tools
```bash
./bin/install.sh desktop-essential
```

**⚡ javascript** - JavaScript/TypeScript development with modern tooling
```bash
./bin/install.sh javascript
```

**⚛️ react** - React development extending JavaScript preset
```bash
./bin/install.sh react
```

**🌐 web** - Complete frontend development with CSS, build tools, deployment
```bash
./bin/install.sh web
```

**📝 markdown** - Technical writing and documentation workflow
```bash
./bin/install.sh markdown
```

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
