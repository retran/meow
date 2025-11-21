# Presets

While components are the low-level building blocks of your environment, **Presets** are the high-level entry point that makes `.meow` powerful and easy to use. Presets are curated lists of components designed to configure a system for a specific purpose.

They are organized into two main concepts: **The Den** for long-lived host machines and **The Litterbox** for ephemeral development environments.

## The Den (Host Configurations)

"The Den" refers to presets designed for your primary, long-lived workstations—your physical macOS or Linux machines. These configurations are meant to be personal and comprehensive, setting up everything from your shell and development tools to your GUI applications and system settings.

The goal of a Den is to create a complete, comfortable, and reproducible home base for all your work and personal projects.

There are two primary Den presets provided by default:

- `den-personal`: This preset is for a complete personal setup. It extends a common base and adds components for development, productivity, communication, and entertainment. It includes components like `gaming`, `media`, and `personal-communication`.

- `den-professional`: This preset is tailored for a corporate or work-focused environment. It builds on the same essential base as the personal preset but omits entertainment software and includes business-oriented tools like `business-communication` (Slack, Zoom).

## The Litterbox (Ephemeral Environments)

"The Litterbox" refers to presets designed for disposable, single-purpose environments. These are perfect for:

- Dev Containers (e.g., VS Code Remote - Containers)
- CI/CD pipelines
- Isolated testing environments

Litterbox presets are minimal by design. They start with a lean base (`litterbox-essential`) which includes core shell utilities, and then add only the specific language toolchains and tools required for a particular project or task. This keeps them lightweight and fast to provision.

Examples include:

- `litterbox-go`: Installs the Go toolchain, debugger, and linters.
- `litterbox-rust`: Installs the Rust toolchain, cargo extensions, and formatters.
- `litterbox-dotnet`: Sets up the .NET SDK and related tools.
- `litterbox-python`: Provides a Python environment with common tools.
- `litterbox-full`: Installs all Linux-compatible components for a fully loaded development environment with multiple language toolchains.

---

## What's Next?

Now that you understand the types of presets available, the next step is to learn how to manage them.

➡️ **[View the Command Reference](./04-COMMAND-REFERENCE.md)** to learn how to `install`, `update`, and `uninstall` presets.
