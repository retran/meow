# meow

Dotfiles management system that automates development environment setup using predefined presets. Part of the `project meow` ecosystem, including [`Meowvim`](https://github.com/retran/meowvim) for Neovim configuration.

## Features

- **Two Main Presets**: personal (full development setup) and corporate (work-focused Go environment)
- **Multi-Package Manager Support**: Homebrew, pipx, npm, Go packages, and Mac App Store
- **Pre-configured Environments**: Go, .NET, Kotlin, Godot, JavaScript, React, and more
- **Automatic Dotfile Linking**: Configuration deployment with dependency resolution
- **Modular Components**: Mix and match for custom setups
- **macOS Support**: Designed for macOS systems with bash 3.2+ compatibility

## Prerequisites

- **Operating System**: macOS
- **Shell**: Bash 3.2+ (default on macOS) or Zsh
- **Internet Connection**: For downloading packages

meow works with the default bash 3.2 that ships with macOS, avoiding dependency issues.

## Installation

Download and install with your preferred preset in one command:

```bash
curl -L https://github.com/retran/meow/archive/main.tar.gz | tar -xz && mv meow-main ~/.meow && cd ~/.meow && ./bin/install.sh personal
```

For corporate environment:
```bash
curl -L https://github.com/retran/meow/archive/main.tar.gz | tar -xz && mv meow-main ~/.meow && cd ~/.meow && ./bin/install.sh corporate
```

## Usage

Update your installed preset:
```bash
./bin/update.sh
```

## Components

meow uses a modular component system with dependency resolution:

### Foundation
- **shell-essential** - Essential shell tools (Git, Tmux, Starship, Neovim)
- **desktop-essential** - GUI foundation for macOS
- **core-development** - Core development tools (depends on shell-essential)

### Programming Languages
- **go-development** - Go development environment
- **javascript** - JavaScript/TypeScript development
- **kotlin-development** - Kotlin environment
- **dotnet-development** - .NET development tools

### Frontend & Web Development
- **react** - React development framework (extends JavaScript)
- **web** - Web development tools (extends React)

### Specialized Development
- **game-development** - Game development tools including Godot
- **markdown** - Technical writing tools

### Communication & Productivity
- **corporate-communication** - Professional communication tools
- **personal-communication** - Personal messaging applications
- **productivity** - Productivity tools

### Entertainment & Media
- **gaming** - Gaming platforms
- **media** - Media editing tools

Components automatically resolve dependencies. Package managers supported: brew, npm, pipx, go packages, Mac App Store, VS Code extensions.

## Troubleshooting

### Installation Issues
```bash
# Ensure proper permissions
chmod +x ~/.meow/bin/*.sh

# For Homebrew issues
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For package manager issues
npm cache clean --force
python -m pip install --upgrade pipx
```

For more help, check the [issues page](https://github.com/retran/meow/issues).

## Contributing

Contributions are welcome:
- Report bugs
- Suggest features or presets
- Submit code improvements
- Enhance configurations

## License

MIT License. See [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with these excellent open-source tools:
- [Homebrew](https://brew.sh/)
- [Neovim](https://neovim.io/)
- [Starship](https://starship.rs/)
- [tmux](https://github.com/tmux/tmux)
- [fzf](https://github.com/junegunn/fzf)
- [ripgrep](https://github.com/BurntSushi/ripgrep)

Developed by Andrew Vasilyev.
