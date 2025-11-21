# Package Configuration

One of the core strengths of `.meow` is its ability to manage packages across diverse operating systems using a unified interface. This document explains how the framework determines which package manager to use, how it matches configurations to your specific OS, and how to add custom package repositories.

## OS Detection and Matching

The framework automatically detects your operating system properties using:

- `uname` (for macOS detection)
- `/etc/os-release` (for Linux distributions)

It extracts the following standard variables:

- `platform`: `macos` or `linux`
- `distro`: The OS ID (e.g., `ubuntu`, `fedora`, `arch`, `alpine`)
- `version_id`: The version number (e.g., `22.04`, `39`)
- `distro_like`: A list of upstream distributions this OS is based on (e.g., `debian` for Ubuntu, `rhel` for Fedora).

### The `match` Block

In `preset.yaml` and `component.yaml` files, you can use a `match` block to apply configurations only to specific systems. A match occurs if **all** specified criteria are met.

**Schema:**

```yaml
match:
  platform: "linux" # Optional: macos | linux
  distro: "ubuntu" # Optional: exact match for OS ID
  version_id: "22.04" # Optional: exact match for Version ID
  distro_like: # Optional: match if OS is "like" one of these
    - "debian"
```

**Examples:**

1.  **Targeting all Debian-based systems:**

    ```yaml
    match:
      distro_like: debian
    ```

2.  **Targeting a specific Ubuntu version:**

    ```yaml
    match:
      distro: ubuntu
      version_id: "24.04"
    ```

3.  **Targeting macOS:**

    ```yaml
    match:
      platform: macos
    ```

## Package Manager Resolution

Before installing any component, `.meow` calculates which package managers are active for the current system. This is resolved by merging configurations from three layers in the following priority order (lowest to highest):

1.  **Default Preset** (`presets/base/preset.yaml`)
2.  **Active Preset** (e.g., `presets/den-personal/preset.yaml`)
3.  **Component** (`components/<name>/component.yaml`)

### Configuring Managers

You can control which package managers are used via the `packages` section in `preset.yaml` or `component.yaml`.

```yaml
packages:
  - match:
      platform: linux
      distro: arch
    managers:
      include:
        - pacman
      exclude:
        - snap
```

- **`include`**: Adds a package manager to the active list.
- **`exclude`**: Explicitly removes a package manager from the list, even if it was added by a lower layer.

This allows a component to say "I support `apt` and `pacman`", while a preset can enforce "On this machine, never use `snap`".

## Custom Package Sources

Sometimes the software you need isn't in the official repositories. `.meow` allows you to define **Package Sources** (repositories, PPAs) directly in your `component.yaml` or `preset.yaml`.

The framework handles the complexity of adding keys, verifying signatures, and configuring source lists.

### Schema

```yaml
package_sources:
  - manager: <manager_name>
    match: <match_block>
    name: <unique_slug>
    repo: <repository_line>
    key_url: <url_to_gpg_key>
    repo_file: <content_for_repo_file>  # For RPM-based distributions (DNF/YUM)
    gpg_key: <url_to_gpg_key>           # For RPM-based distributions (DNF/YUM)
```

**Field Descriptions:**

- `manager`: The package manager this source applies to (e.g., `apt`, `dnf`, `pacman`)
- `match`: Optional matching criteria to target specific distributions
- `name`: A unique identifier for this package source
- `repo`: For APT-based systems, the repository line to add to sources.list
- `key_url`: For APT-based systems, URL to the GPG key for package verification
- `repo_file`: For RPM-based distributions (DNF/YUM), the complete content of the `.repo` file to be created in `/etc/yum.repos.d/`
- `gpg_key`: For RPM-based distributions (DNF/YUM), URL to the GPG key that will be imported via `rpm --import`

### Templating

You can use the following placeholders in `repo` and `repo_file` strings. They will be replaced with the actual values from the target system at runtime:

- `{{VERSION_ID}}`: e.g., `22.04`
- `{{VERSION_CODENAME}}`: e.g., `jammy`
- `{{DISTRO}}`: e.g., `ubuntu`
- `{{PLATFORM}}`: e.g., `linux`

### Examples

**1. Adding an APT Repository (Docker):**

```yaml
package_sources:
  - manager: apt
    match:
      distro: ubuntu
    name: docker
    repo: "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) {{VERSION_CODENAME}} stable"
    key_url: "[https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg)"
```

_Note: For `apt`, if a `key_url` is provided, the key is automatically downloaded, de-armored (if necessary), and installed to `/usr/share/keyrings/<component>-<name>.gpg`._

**2. Adding a DNF Repository (VS Code):**

```yaml
package_sources:
  - manager: dnf
    match:
      distro_like: fedora
    name: vscode
    repo_file: |
      [code]
      name=Visual Studio Code
      baseurl=[https://packages.microsoft.com/yumrepos/vscode](https://packages.microsoft.com/yumrepos/vscode)
      enabled=1
      gpgcheck=1
      gpgkey=[https://packages.microsoft.com/keys/microsoft.asc](https://packages.microsoft.com/keys/microsoft.asc)
    gpg_key: "[https://packages.microsoft.com/keys/microsoft.asc](https://packages.microsoft.com/keys/microsoft.asc)"
```

_Note: For `dnf`, `repo_file` contains the actual content of the `.repo` file. `gpg_key` triggers an `rpm --import`._

## Package Lists

Once managers and sources are configured, defining packages is simple. Create a file in the component's `packages/` directory named after the package manager:

- `components/my-tool/packages/apt.list`
- `components/my-tool/packages/homebrew.list`
- `components/my-tool/packages/pacman.list`

**Format:**
One package name per line. Lines starting with `#` are comments.

```text
# core tools
git
curl
# languages
python3
```

The framework will only try to install packages from lists corresponding to **active** package managers for the current platform.
