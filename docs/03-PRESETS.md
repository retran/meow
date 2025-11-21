# Presets

While components are the low-level building blocks of your environment, **Presets** are the high-level entry point that makes `.meow` powerful and easy to use. Presets are curated lists of components designed to configure a system for a specific purpose.

They are organized into two main concepts: **The Den** for long-lived host machines and **The Litterbox** for ephemeral development environments.

## The Den (Host Configurations)

"The Den" refers to presets designed for your primary, long-lived workstations—your physical macOS or Linux machines. These configurations are meant to be personal and comprehensive, setting up everything from your shell and development tools to your GUI applications and system settings.

The goal of a Den is to create a complete, comfortable, and reproducible home base for all your work and personal projects.

There are two primary Den presets provided by default:

-   `den-personal`: This preset is for a complete personal setup. It extends a common base and adds components for development, productivity, communication, and entertainment. It includes components like `gaming`, `media`, and `personal-communication`.

-   `den-professional`: This preset is tailored for a corporate or work-focused environment. It builds on the same essential base as the personal preset but omits entertainment software and includes business-oriented tools like `business-communication` (Slack, Zoom).

## The Litterbox (Ephemeral Environments)

"The Litterbox" refers to presets designed for disposable, single-purpose environments. These are perfect for:

-   Dev Containers (e.g., VS Code Remote - Containers)
-   CI/CD pipelines
-   Isolated testing environments

Litterbox presets are minimal by design. They start with a lean base (`litterbox-essential`) which includes core shell utilities, and then add only the specific language toolchains and tools required for a particular project or task. This keeps them lightweight and fast to provision.

Examples include:

-   `litterbox-go`: Installs the Go toolchain, debugger, and linters.
-   `litterbox-rust`: Installs the Rust toolchain, cargo extensions, and formatters.
-   `litterbox-dotnet`: Sets up the .NET SDK and related tools.
-   `litterbox-python`: Provides a Python environment with common tools.

## Composition: Creating Your Own Presets

The real power of `.meow` comes from creating your own presets to match your exact needs. A preset is simply a directory containing a `preset.yaml` file that lists the components to be installed.

### Preset File Structure

The `preset.yaml` file supports several powerful configuration options:

-   `description` (string): A brief description of what the preset is for.

-   `extends` (array, optional): A list of other presets to inherit from. Components and configurations from the extended presets will be included automatically. This is useful for building on a common base.

-   `required` (array, optional): A list of components to install as part of this preset.

-   `platforms` (array, optional): Restricts the preset to specific operating systems. If the current OS does not match an entry in this list, the preset will not be available. This is used by the `is_preset_available` logic.
    ```yaml
    platforms:
      - macos
      - linux
    ```

-   `packages` (array, optional): This section does not define individual packages to be installed. Instead, it **configures the package managers** that will be used by the components. You can define rules to include or exclude certain package managers based on the platform.
    ```yaml
    # In presets/base/preset.yaml
    packages:
      - match:
          platform: "macos"
        managers:
          include: ["brew", "mas"]
      - match:
          platform: "linux"
          distro: "ubuntu"
        managers:
          include: ["apt"]
    ```

-   `package_sources` (array, optional): This section allows a preset to define **custom package repositories**, making new packages available to the system's package managers. This is how a preset can "provide its own packages."
    ```yaml
    # Example of adding a custom repository
    package_sources:
      - manager: apt
        match:
          platform: "linux"
          distro: "ubuntu"
        name: "my-custom-repo"
        repo: "deb [arch=amd64] https://my-repo.example.com/ubuntu focal main"
        key_url: "https://my-repo.example.com/key.gpg"
    ```

### Example: Creating a Custom "Den"

Let's say you want to create a `my-den` preset that is similar to `den-professional` but also includes the `media` component for video editing.

1.  **Create the preset directory:**

    ```bash
    mkdir -p presets/my-den
    ```

2.  **Create the `preset.yaml` file:**

    Create the file `presets/my-den/preset.yaml` with the following content:

    ```yaml
    # presets/my-den/preset.yaml
    description: My custom professional den with media tools.

    extends:
      - den-professional

    required:
      - media
    ```

3.  **Install your new preset:**

    You can now [`install`](./05-COMMAND-REFERENCE.md#meowctl-install) your custom preset just like any other:

    ```bash
    ./bin/meowctl install my-den
    ```

The framework will automatically handle the rest: it will pull in all the components from `den-professional` (which itself extends `den-essential` and `base`), add the `media` component, resolve all dependencies, and install everything in the correct order.

---

## What's Next?

You now know how to choose and even create a preset. The next step is to use the `meowctl` command-line tool to manage them.

➡️ **[View the Command Reference](./05-COMMAND-REFERENCE.md)** to learn how to `install`, `update`, and `uninstall` presets.
