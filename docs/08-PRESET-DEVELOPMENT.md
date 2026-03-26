# Preset Development Guide

Presets are the primary mechanism in `.meow` for defining a complete development environment. Unlike components, which are granular and focused on specific tools, presets are declarative compositions that bundle multiple components together to serve a specific role (e.g., "Personal Workstation" or "Go Backend Dev").

This guide explains how to create, customize, and extend presets.

## Directory Structure

A preset is simply a directory located in `presets/` containing a single manifest file named `preset.yaml`.

```

presets/
└── my-custom-preset/
└── preset.yaml

```

The name of the directory (`my-custom-preset`) becomes the name of the preset used in CLI commands like `meowctl install my-custom-preset`.

## The Manifest: `preset.yaml`

The `preset.yaml` file defines the preset's metadata, its dependencies on other presets, the components it requires, and system-level configurations.

### Schema Overview

```yaml
description: "A short description of the preset"

platforms: # Optional: Restrict to specific OSs
  - macos
  - linux

extends: # Optional: Inherit from other presets
  - base
  - den-essential

required: # Optional: List of components to install
  - my-component
  - another-component

packages: # Optional: Configure package managers
  - match:
      platform: linux
    managers:
      include: [apt]
      exclude: [snap]

package_sources: # Optional: Add custom repositories
  - manager: apt
    name: my-repo
    repo: "deb [https://example.com/repo](https://example.com/repo) stable main"
```

### 1\. `required`: defining Components

The core function of a preset is to list the components that should be installed.

```yaml
required:
  - shell-essential
  - neovim
  - docker-cli
```

When `meowctl install` runs, it collects all components listed here, resolves their dependencies (defined in each component's `component.yaml`), and calculates the correct installation order.

### 2\. `extends`: Inheritance and Composition

Presets can inherit from other presets. This allows you to create a hierarchy of configurations, avoiding duplication.

```yaml
extends:
  - base
  - den-essential
```

**How it works:**

1.  The framework recursively reads all presets listed in `extends`.
2.  It merges the `required` lists from all parent presets with the current preset.
3.  It merges `packages` and `package_sources` configurations.

**Best Practice:**
Most presets should extend `base`. The `base` preset typically configures the package managers for the OS (e.g., enabling `homebrew` on macOS and `apt` on Debian), but installs no components.

### 3\. `platforms`: OS Restrictions

You can restrict a preset to specific operating systems. If the user attempts to install the preset on an unsupported platform, `meowctl` will reject the request.

```yaml
platforms:
  - match:
      platform: macos
  - match:
      platform: linux
      distro: ubuntu
```

If the `platforms` block is omitted, the preset is assumed to be available on all systems (though individual components inside it might still fail if they don't support the OS).

### 4\. `packages`: Package Manager Configuration

This section controls **which** package managers are active for components within this preset. It does not install packages directly; rather, it tells the framework "On this OS, allow components to use `apt`, but forbid `snap`."

```yaml
packages:
  - match:
      platform: macos
    managers:
      include:
        - homebrew
        - mas
  - match:
      platform: linux
      distro: arch
    managers:
      include:
        - pacman
```

- **`include`**: Enables the specified package managers.
- **`exclude`**: Explicitly disables a manager, even if a parent preset included it.

For more details on the matching logic, see [Package Configuration](https://www.google.com/search?q=./07-PACKAGE-CONFIGURATION.md).

### 5\. `package_sources`: Custom Repositories

Presets can inject custom package repositories into the system. This is useful for corporate environments or when using software not present in standard distro repositories.

```yaml
package_sources:
  - manager: apt
    match:
      distro: ubuntu
    name: "corp-repo"
    repo: "deb [https://apt.corp.example.com/](https://apt.corp.example.com/) stable main"
    key_url: "[https://apt.corp.example.com/key.gpg](https://apt.corp.example.com/key.gpg)"
```

## Tutorial: Creating a Custom "Den"

Let's say you want to create a customized setup called `my-den` that builds upon the standard professional setup but adds video editing tools (`media` component) and some personal configuration overrides.

**Step 1: Create the directory**

```bash
mkdir -p presets/my-den
```

**Step 2: Define the preset**

Create `presets/my-den/preset.yaml`:

```yaml
description: My custom workspace for coding and video editing.

# Inherit the robust configuration from the professional den
extends:
  - den-professional

# Add extra components specific to my needs
required:
  - media
  - gaming
```

**Step 3: Install**

You can now apply this preset to your machine:

```bash
meowctl install my-den
```

The framework will:

1.  Load `den-professional` (and its parents `den-essential`, `base`).
2.  Combine the component lists.
3.  Detect that `media` and `gaming` are required.
4.  Install everything in the correct topological order.

## Tips for Preset Design

- **Keep it Modular**: Don't create a monolithic "everything" preset. Use `extends` to build layers (e.g., `base` -\> `headless` -\> `desktop` -\> `workstation`).
- **Platform Agnosticism**: Try to make presets work across OSs by selecting components that support both macOS and Linux. Use the `platforms` restriction only when a preset is inherently specific to one OS.
