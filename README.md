<div align="center">
  <h1>Brain_Shell</h1>
  <h3>A dynamic, modular Wayland desktop shell built with Quickshell and QML. Currently built for Hyprland, with support for additional compositors planned.</h3>
</div>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/Brainitech/Brain_Shell?style=for-the-badge&color=8D748C&logoColor=D9E0EE&labelColor=252733" alt="Last Commit" />
  <img src="https://img.shields.io/github/stars/Brainitech/Brain_Shell?style=for-the-badge&logo=starship&color=AB6C6A&logoColor=D9E0EE&labelColor=252733" alt="Stars" />
  <img src="https://img.shields.io/badge/version-0.2.0-8D748C?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Version 0.2.0" />
  <br>
  <img src="https://img.shields.io/badge/hyprland-v0.55+-5E81AC?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Hyprland v0.55+" />
  <img src="https://img.shields.io/badge/framework-quickshell-A1C999?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Quickshell Framework" />
  <br>
  <a href="https://github.com/Brainitech/Brain_Shell/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Brainitech/Brain_Shell?style=for-the-badge&color=A1C999&logo=opensourceinitiative&logoColor=D9E0EE&labelColor=252733&v=2" alt="License" />
  </a>
  <a href="https://github.com/Brainitech/Brain_Shell/issues">
    <img src="https://img.shields.io/github/issues/Brainitech/Brain_Shell?style=for-the-badge&logo=github&color=5E81AC&logoColor=D9E0EE&labelColor=252733" alt="Issues" />
  </a>
  <a href="https://discord.gg/aGbUM8PUts">
    <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FaGbUM8PUts%3Fwith_counts%3Dtrue&query=approximate_member_count&style=for-the-badge&logo=discord&logoColor=D9E0EE&label=discord&labelColor=252733&color=7289DA" alt="Discord Invite" />
  </a>
</p>

---

## Showcase

<div align="center">
  <video src="https://github.com/user-attachments/assets/f78da771-15b9-4131-bc6a-92169ad0ccd9" controls="controls" style="max-width: 100%; height: auto;">
  </video>
</div>

---

> [!NOTE]
> **v0.2.0 Release:** This is a ground-up architecture overhaul. While far more stable than `v0.1.1`, you may still encounter bugs. Please report them via GitHub Issues or Join our [Discord](https://discord.gg/aGbUM8PUts).
>
> **Platform Scope:** Brain_Shell is currently built for **Hyprland**, and officially supported on **Arch Linux** and **NixOS**. Other distros may work, but aren't guaranteed yet. See [Roadmap](#roadmap).
>
> **AI Assistance Notice:** Certain elements of this project _(like architectural planning, codebase audits, GitHub workflows, debugging, and large-scale cleanups)_ were developed with the assistance of AI tools.
>
> **License Notice:** As of `v0.2.0`, the project license has been migrated from **MIT** to the **GNU Affero General Public License v3.0 (AGPLv3)**.

---

## What's New

For a complete breakdown of new features, architectural improvements, and bug fixes in v0.2.0, see [CHANGELOG.md](CHANGELOG.md) or the [GitHub Releases](https://github.com/Brainitech/Brain_Shell/releases) page.

---

## Features

- **Fluid Interface & Animations:** A responsive UI that automatically scales to fit your monitor's resolution, smoother than a perfectly timed parry. Features configurable animation speeds and styles.

- **Dynamic Theming & Presets:** System colors automatically adapt to your active wallpaper, backed by 12 popular theme presets, independent color overrides, and an integrated color studio.

- **Keyboard & GUI Driven:** The best of both worlds. Full keyboard navigation when you want speed, and a clean GUI mouse based control for both situations.

- **System Dashboard:** A unified hub for quick settings, media controls, user profile access, and built-in time tools (alarms, timers, and stopwatches).

- **Performance Monitoring:** Live resource tracking for CPU, RAM, battery, and temperatures. Includes dedicated fan and GPU controls for supported Nvidia devices.

- **Built-in Kanban Board:** Desktop-integrated To-Do, Ongoing, and Completed task lists with support for customizable priority tags and deadlines.

- **Smart App Launcher:** A fast, search-driven application menu that learns and prioritizes your most frequently used apps.

- **Interactive Notch:** A sleek drop-down area at the top of your screen that houses quick media controls, an audio visualizer, and other handy, glanceable tools.

- **Live Settings Configuration:** Adjust layout dimensions, visual behavior, and data preferences on the fly without restarting the shell. (More customization options are planned for future updates).

- **Screen Recording & Capture:** Fully integrated screenshot and screen recording tools with support for region/window selection, audio inclusion, configurable FPS, and multiple encoding backends (wf-recorder, gpu-screen-recorder, wl-screenrec).

- **Intelligent Keybinds:** A visual keybind editor equipped with live conflict detection to prevent overlapping shortcuts.

- **Connectivity Manager:** A centralized menu to toggle and connect to Wi-Fi networks, Bluetooth devices, VPNs, and hotspot.

- **Audio & Media Hub:** Quick input/output device switching and a full audio mixer, paired with clean on-screen displays (OSD) for volume and brightness.

- **Smart Notifications:** Interactive desktop alerts featuring hover-to-pause and click-to-dismiss functionality.

- **Built-in Screen Capture:** Native tools for taking screenshots and recording your screen, with options to select specific targets, framerates, and audio capture.

- **Clipboard History:** A interactive clipboard manager fully integrated with keyboard navigation support.

- **Power Menu:** A keyboard-optimized menu for executing shutdown, restart, lock, and sleep actions.

- **Workspace & Layout Management:** Monitor Active workspaces and Switch Hyprland Layouts with a single Click.

- **Focus Mode:** Hides the status bar to provide a clean, distraction-free screen.

- **Eye Care & Nightlight:** Built-in screen color filters and a warm nightlight mode for low-light environments.

- **OS Branding:** Displays a custom icon based on your operating system for a native, personalized feel.

---

## Requirements

> [!IMPORTANT]
> **Matugen is required** for dynamic color generation. Brain_Shell will not function correctly without it.
>
> The dependencies below are for the currently supported compositor, **Hyprland**. Requirements for additional compositors will be documented as support for them lands - Have a look at the [Roadmap](#roadmap).

### Core Dependencies

<details>
<summary><b>Runtime & Rendering</b></summary>

- **Hyprland** v0.55+ - Wayland compositor
- **quickshell** - QML shell framework
- **Qt6** - Qt6 libraries and QML engine
- **qt6ct** - Qt6 theme configuration

</details>

<details>
<summary><b>System Tools</b></summary>

- **PipeWire** - Audio server (pipewire, pipewire-pulse, wireplumber)
- **NetworkManager** - Network management
- **BlueZ** - Bluetooth stack (bluez, bluez-utils)
- **Brightnessctl** - Backlight control
- **Mpris** - Media Retrieval
- **Playerctl** - Player controls
- **UPower** - Battery and power info
- **libnotify** - Desktop notifications
- **Polkit** - Privilege escalation
- **wl-clipboard** - Wayland clipboard (wl-copy/wl-paste)
- **xdg-user-dirs** - Manage user directories
- **util-linux** - Standard Linux utilities

</details>

<details>
<summary><b>Theming & Wallpaper</b></summary>

- **Matugen** - Material You color generation **(REQUIRED)**
- **awww** - Wallpaper daemon (Wayland)
- **ImageMagick** - Image manipulation

</details>

<details>
<summary><b>Screen Capture & Utilities</b></summary>

- **wf-recorder** - Screen recording (Wayland, default backend)
- **gpu-screen-recorder** - Optional recording backend (GPU encoding)
- **wl-screenrec** - Optional recording backend (lightweight)
- **grimblast** - Screenshot utility (Wayland)
- **cava** - Audio visualizer
- **slurp** - Region/window selection
- **wtype** - Keyboard input emulation
- **cliphist** - Clipboard history manager

</details>

<details>
<summary><b>Hardware Management</b></summary>

- **lm_sensors** - CPU temperature & fan monitoring
- **rfkill** - Airplane mode control
- **[envycontrol](https://github.com/bayasdev/envycontrol)** - GPU switching (NVIDIA/Intel hybrid laptops)
- **auto-cpufreq** - CPU frequency scaling
- **[nbfc-linux](https://github.com/nbfc-linux/nbfc-linux)** - Laptop fan control

</details>

<details>
<summary><b>Hyprland Integration</b></summary>

- **hyprlock** - Lock screen
- **hypridle** - Idle management daemon
- **hyprsunset** - Blue light filter
- **xdg-desktop-portal-hyprland** - Portal backend
- **xdg-desktop-portal-gtk** - GTK Portal backend
- **hyprpolkitagent** - Polkit authentication agent

</details>

<details>
<summary><b>Fonts</b></summary>

- **ttf-jetbrains-mono-nerd** - Primary font (Nerd Font variant)
- **ttf-noto-nerd** - Emoji and CJK support
- **ttf-nerd-fonts-symbols-common** - Symbols support

</details>

### Installation Commands (Manual)

> [!IMPORTANT]
> **Brain_Shell** is a **standalone shell** designed to run on top of an existing compositor configuration.
> However, a default Hyprland template is provided for users setting up their environment directly from a TTY.

<details>
<summary><b>Arch Linux (yay / paru)</b></summary>

```bash
# 1. Core Official Repository Packages (42 essential dependencies)
sudo pacman -S --needed \
  qt6-base qt6-declarative qt6-wayland qt6-multimedia qt6-5compat qt6ct \
  pipewire pipewire-pulse wireplumber playerctl mpv-mpris mpd-mpris networkmanager \
  bluez bluez-utils brightnessctl upower libnotify polkit kitty python \
  wl-clipboard slurp xdg-user-dirs wf-recorder cava imagemagick awww matugen \
  wtype lm_sensors util-linux rfkill hyprland hyprsunset hyprlock hyprpolkitagent \
  hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common cliphist

# 2. AUR Packages (using yay, replace with paru if preferred)
yay -S --needed quickshell-git grimblast-git

# 3. Optional Hardware Management & Tools (Install only if applicable)
# For Hybrid NVIDIA Laptops:
yay -S --needed envycontrol
# For Laptop Fan Control:
yay -S --needed nbfc-linux
# For Laptop Power Optimization:
yay -S --needed auto-cpufreq

```

</details>

---

## Installation

> [!WARNING]
> **Notes for Existing Users**
>
> 1. If you installed Brain_Shell via the installer, **v0.2.0 will be pulled in automatically** through the auto-update mechanism, a manual reinstall is **not required**.
> 2. That said, v0.2.0 includes **breaking architectural and config changes**. If you run into migration issues (or want a guaranteed clean slate), a **full uninstall followed by a fresh install** is recommended - Have a look at the [Uninstallation](#uninstallation) below.

### One line installer

> [!TIP]
> **Automated Setup:** The installation script verifies system prerequisites, creates a timestamped backup of your Hyprland configuration in `~/.config/hypr/`, installs dependencies via your package manager, and registers Brain_Shell in your autostart.

```bash
curl -fsSL https://raw.githubusercontent.com/Brainitech/Brain_Shell/refs/heads/main/install.sh | bash
```

The installer automatically:

- ✓ Detects your Linux distribution and window manager.
- ✓ Backs up your existing Hyprland configuration file.
- ✓ Installs all required dependencies.
- ✓ Clones the repository to `~/.local/src/Brain_Shell`.
- ✓ Updates your Hyprland config to auto-start Brain_Shell.
- ✓ Provides a default Hyprland template for users with no previous Hyprland install.

> [!IMPORTANT]
> If you're on `OMARCHY` then disable the `omarchy-shell` startup line located in `/usr/share/omarchy/default/hypr/autostart.lua`
> Comment out the line `hl.exec_cmd("omarchy-shell-launch")`
> Failing to do this will interfere with `Brain_Shell`'s Notification and Wallpaper Manager.
> The Installer should already do this if it detects Omarchy.

---

### NixOS & Home Manager

Brain_Shell provides official, declarative NixOS and Home Manager flake modules. Dependencies, system services, fonts, and Hyprland integration are all configured automatically.

> [!IMPORTANT]
> Brain_Shell requires **nixos-unstable** (or a recent nixpkgs snapshot). Stable channels may lack required packages such as `quickshell` and `awww`.

---

#### NixOS System Module

The NixOS module enables system-level services (PipeWire, Bluetooth, Polkit, XDG portals), installs all runtime packages system-wide, and places `brain-shell` on `$PATH`.

**1. Add Brain_Shell to your system flake (`/etc/nixos/flake.nix`):**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    brain-shell = {
      url = "github:Brainitech/Brain_Shell?ref=fix/nix-testing";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, brain-shell, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      modules = [
        brain-shell.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

**2. Enable the module in `configuration.nix`:**

```nix
programs.brain-shell.enable = true;
```

**3. Rebuild:**

```bash
sudo nixos-rebuild switch --flake /etc/nixos/
```

After the rebuild, add the Brain_Shell autostart to your Hyprland config (see [Hyprland Integration on NixOS](#hyprland-integration-on-nixos) below).

---

#### Home Manager Module

The Home Manager module handles user-level installation, fonts, and the systemd autostart service. It can also auto-inject Brain_Shell's layer rules and keybinds into your Hyprland config.

**1. Add Brain_Shell to your Home Manager flake:**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brain-shell = {
      url = "github:Brainitech/Brain_Shell?ref=fix/nix-testing";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, brain-shell, ... }: {
    homeConfigurations.username = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        brain-shell.homeManagerModules.default
        ./home.nix
      ];
    };
  };
}
```

**2. Enable in `home.nix`:**

```nix
{ pkgs, ... }:

{
  # Default Stuff

  programs.brain-shell = {
    enable = true;

    # systemd.enable = false;
    #   Autostart Brain Shell via a systemd user service bound to graphical-session.target.
    #   Default: false. When false, an exec_cmd hook is injected into Hyprland instead.
    #   Set to true if you prefer systemd to manage the session.

    # installDefaultHyprlandConfig = false;
    #   Deploys Brain_Shell's bundled Hyprland config template to ~/.config/hypr/.
    #   Useful for fresh Hyprland installs with no existing configuration.
    #   Default: false. WARNING: this overwrites existing hyprland.lua.

    # hyprlandIntegration = {
    #   enable = true; # default
    #   format = "lua"; # "lua" or "conf" (default: "lua")
    # };
    #   Writes ~/.config/hypr/lua.d/brain-shell.lua (or conf.d/brain-shell.conf)
    #   with layer rules and the dynamic keybind source line. Disable if you
    #   manage hyprland config yourself and want full control.

    # terminal = "kitty";
    #   Terminal emulator used for nmtui and screenshot previews. Default: "kitty".

    # extraPackages = [ ];
    #   Additional packages installed alongside Brain Shell in the user profile.
    #   Example: [ pkgs.gpu-screen-recorder pkgs.envycontrol ]
  };
}
```

**3. Switch your profile:**

```bash
home-manager switch --flake ~/.config/home-manager/
```

---

#### Hyprland Integration on NixOS

If `hyprlandIntegration.enable = true` (default) in your Home Manager config, Brain_Shell drops its layer rules and keybinds right into `~/.config/hypr/lua.d/brain-shell.lua`. No extra config needed.

If you manage your Hyprland configuration manually or prefer the system-level NixOS module, add the following snippets yourself:

<details open>
<summary><b>For <code>~/.config/hypr/hyprland.lua</code> (Lua format — Recommended for Hyprland 0.55+)</b></summary>

```lua
-- Brain Shell layer rules — required for correct rendering
hl.layer_rule({ match = { namespace = "^brain-shell.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true, ignore_alpha = 1 })

-- Dynamic keybinds managed by Brain Shell's visual editor
local kb_path = os.getenv("HOME") .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua"
local f = io.open(kb_path, "r")
if f then f:close(); dofile(kb_path) end
```

If Brain Shell is **not** started by systemd (i.e., `systemd.enable = false` or using the NixOS system module without Home Manager), also add the autostart hook:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("brain-shell")
end)
```

</details>

<details>
<summary><b>For <code>~/.config/hypr/hyprland.conf</code> (Hyprlang format — Fallback option)</b></summary>

```ini
# Brain Shell layer rules — required for correct rendering
layerrule = noanim, ^(brain-shell.*)$
layerrule = noanim, selection
layerrule = ignorealpha 1, selection

# Dynamic keybinds managed by Brain Shell's visual editor
source = ~/.config/Brain_Shell/Brain_ShellKeybinds.conf
```

If Brain Shell is **not** started by systemd (i.e., `systemd.enable = false` or using the NixOS system module without Home Manager), also add:

```ini
exec-once = brain-shell
```

</details>

> [!NOTE]
> Brain_Shell keeps its runtime state (`~/.config/Brain_Shell/src/user_data/`, `matugen/`, keybindings) mutable and initializes it on first launch. This means you can still use the visual editor and tweak settings inside the shell, while Nix handles the core package and services.

---

### Manual installation

```bash
git clone https://github.com/Brainitech/Brain_Shell.git
cd Brain_Shell
chmod +x install.sh
./install.sh
```

**Starting the Shell Manually:**
If you choose to bypass the installer script entirely and configure the environment yourself, you must manually ensure the startup files are executed by your compositor.

1. Make sure required dependencies are installed (see the [Requirements](#requirements) section).
2. Ensure the required `matugen` directory exists:
   ```bash
   mkdir -p ~/.config/Brain_Shell/matugen
   ```
3. Source the autostart file directly in your main Hyprland configuration.

For `hyprland.lua`, inject:

```lua
dofile(os.getenv("HOME") .. "/path/to/Brain_Shell/src/config/autostart/BrainShell-hyprland.lua")
```

For `hyprland.conf`, inject:

```conf
source = ~/path/to/Brain_Shell/src/config/autostart/BrainShell-hyprland.conf
```

**After installation, restart Hyprland for changes to take effect.**
Or manually start the required background services:

```bash
awww-daemon & #if not running already
hypridle &
systemctl --user start hyprpolkitagent
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
hyprctl reload
qs -p ~/path/to/Brain_Shell &
```

---

### Hardware Configuration (Optional)

If your setup utilizes hybrid graphics or laptop fan control, additional configuration is required after installing the optional packages:

#### Laptop Fan Control ([nbfc-linux](https://github.com/nbfc-linux/nbfc-linux))

Enables real-time fan monitoring and quiet/auto/max profile switching in the Dashboard (`FanPanel`):

```bash
#Enable and start the background service:
sudo systemctl enable --now nbfc_service

#Find and apply your laptop's profile:**
# Search for recommended configurations matching your laptop model
nbfc config --recommend

# Apply the chosen model profile and start fan control
nbfc config -s "<Profile_Name>"
nbfc start

#Verify status:
nbfc status
```

> [!IMPORTANT]
> If the above steps don't work, visit the official [nbfc-linux's](https://github.com/nbfc-linux/nbfc-linux) github page.

#### Hybrid GPU Switching ([envycontrol](https://github.com/bayasdev/envycontrol))

Enables GPU power mode switching (`Integrated`, `Hybrid`, `Dedicated`) in the Dashboard (`PowerPanel`):

- **Prerequisites:** Laptops with hybrid NVIDIA graphics (NVIDIA Optimus) and an active polkit agent (e.g., `hyprpolkitagent`).
  > [!WARNING]
  > **Behavior:** Switching modes in the Dashboard triggers root authorization via `pkexec` and **automatically initiates a reboot** to apply the necessary display manager and driver/kernel module changes.
- **Verify status manually:**
  ```bash
  sudo envycontrol --query
  ```

---

## Getting Started & Keybindings

| Shortcut      | Target Action  | Description                                                         |
| :------------ | :------------- | :------------------------------------------------------------------ |
| `SUPER + D`   | Dashboard      | Open/close main dashboard hub (system stats, media, profile, clock) |
| `SUPER + Q`   | App Launcher   | Open search-driven application launcher                             |
| `SUPER + C`   | Settings       | Open shell customization and visual preferences panel               |
| `SUPER + ESC` | Power Menu     | Open session controls (shutdown, reboot, lock, logout)              |
| `SUPER + V`   | Clipboard      | Open clipboard history manager                                      |
| `SUPER + Z`   | Kanban Board   | Open desktop task management board                                  |
| `CTRL + ESC`  | Emergency Exit | Unfreeze keybindings and reset active Hyprland submap               |

---

## CLI Wrapper & IPC Integration

### Command Line Interface (`brain-shell`)

When installed via NixOS or Home Manager, the `brain-shell` executable is available globally on your `$PATH`:

```bash
# Launch Brain Shell directly with bundled dependencies
brain-shell

# Send IPC toggle commands
brain-shell ipc call <TARGET> toggle
```

### IPC Integration

Brain_Shell provides an IPC interface via Quickshell's IPC subsystem. You can trigger surfaces from Hyprland keybinds, scripts, or terminal commands:

**NixOS / Home Manager:**

```bash
brain-shell ipc call <TARGET> toggle
```

**Arch Linux / Manual Installation:**

```bash
qs ipc -p ~/.local/src/Brain_Shell call <TARGET> toggle
```

| IPC Target            | Description                        |
| :-------------------- | :--------------------------------- |
| `dashboard-home`      | Toggle main dashboard              |
| `dashboard-stats`     | Toggle dashboard stats             |
| `dashboard-kanban`    | Toggle dashboard kanban            |
| `dashboard-launcher`  | Toggle dashboard launcher          |
| `dashboard-config`    | Toggle dashboard config            |
| `audioOut-toggle`     | Toggle audio mixer output          |
| `audioMix-toggle`     | Toggle audio mixer                 |
| `audioIn-toggle`      | Toggle audio mixer input           |
| `wifi-toggle`         | Toggle wifi network                |
| `bluetooth-toggle`    | Toggle bluetooth network           |
| `vpn-toggle`          | Toggle vpn network                 |
| `hotspot-toggle`      | Toggle hotspot network             |
| `notification-toggle` | Toggle notifications               |
| `clipboard-toggle`    | Toggle clipboard history           |
| `wallpaper-toggle`    | Toggle wallpaper menu              |
| `PowerMenu-toggle`    | Toggle power menu                  |
| `screenrec-on`        | Toggle screen recording setup      |
| `focus-toggle`        | Toggle distraction-free focus mode |
| `lock-session`        | Lock the session                   |
| `screenshot-toggle`   | Toggle screenshot utility          |

---

## Uninstallation

_Giving up already? YOU DIED. (Just kidding, here's how to safely remove it without losing your soul):_

To completely remove Brain_Shell and restore your previous configuration:

### Arch Linux / Manual Installation

```bash
# 1. Kill Currently Running Shell (if running)
pkill quickshell || pkill qs || true
# 2. Remove cloned repository and user configuration
rm -rf ~/.local/src/Brain_Shell
rm -rf ~/.config/Brain_Shell

# 3. Remove the Brain_Shell autostart line from your Hyprland configuration (hyprland.lua / hyprland.conf)
```

### NixOS / Home Manager

1. Remove `programs.brain-shell.enable = true;` from your flake / system / Home Manager configuration.
2. Rebuild your system (`sudo nixos-rebuild switch --flake /etc/nixos/`) or Home Manager profile (`home-manager switch`).
3. Optionally remove user configuration and state:

```bash
rm -rf ~/.config/Brain_Shell
```

---

## Roadmap

### Current (v0.2.0)

- [x] Core shell framework
- [x] System monitoring dashboard
- [x] Keybind editor with live conflict detection
- [x] Network management (WiFi, Bluetooth, VPN)
- [x] Audio control panel
- [x] Screen recording integration
- [x] Clipboard manager
- [x] Material You color integration
- [x] Lua config generation
- [x] Professional installer (Arch/NixOS)
- [x] Auto-update mechanism with release-based updates
- [x] Scaling on Different Screen Sizes
- [x] Config Pages for Shell Customization
- [x] App Launcher frecency-based sorting
- [x] Unified popup configuration layer
- [x] Notch Mini Player
- [x] First-class NixOS & Home Manager Flake integration

### Upcoming

#### Compositor & Distro Support

- [ ] niri support
- [ ] Sway support
- [ ] Other Compositor support
- [ ] Broader distribution support (Fedora, Debian/Ubuntu, openSUSE)

#### Customization & Ecosystem

- [ ] Advanced Customization Options
- [ ] Compositor-Specific GUI Settings
- [ ] Community themes
- [ ] Plugin/extension API for third-party widgets
- [ ] Additional theme presets

#### Tooling & Documentation

- [x] CLI for Brain_Shell (`brain-shell` wrapper with IPC forwarding)
- [ ] Extended documentation site
- [ ] Onboarding guide

---

## Known Issues

If you encounter an unlisted issue, capture debug output by running `brain-shell` (on NixOS) or `qs -p ~/.local/src/Brain_Shell` (on Arch Linux) in a terminal or inspecting systemd logs, then file a report on GitHub Issues.

- **Keybind Conflict Detection Failure:** The conflict detector may fail or incorrectly map binds in certain edge cases.
- **Lua Keybind Resolution:** Hyprland Lua keybinds that lack explicit descriptions are currently falling back and being read generically as the line number in the code.
- **Context Aware Multi-Monitor Behavior:** On a multi-monitor setup, the shell behaves the same on all monitors.

---

## Contributing

Brain_Shell is actively developed and welcomes contributions!

- Found a bug? → [Open an issue](https://github.com/Brainitech/Brain_Shell/issues)
- Have an idea? → [Start a discussion](https://github.com/Brainitech/Brain_Shell/discussions)
- Want to contribute? → Have a look at [CONTRIBUTING.md](CONTRIBUTING.md)
- Want to join the community? → [Join Discord](https://discord.com/invite/BV8UduvABx)

---

## Special Thanks

- **[Hyprland Community](https://github.com/hyprwm):** For creating an exceptional Wayland compositor and fostering an amazing community
- **[Quickshell Contributors](https://git.outfoxxed.me/quickshell):** For the powerful QML framework that powers this shell
- **[Matugen Team](https://github.com/InioX/matugen):** For Material You color generation technology
- **[Wayland Project](https://wayland.freedesktop.org):** For the modern display protocol foundation
- **[Caelestia Shell](https://github.com/caelestia-dots/shell)** & **[AX-Shell](https://github.com/Axenide/ax-shell):** For the inspiration
- **[Dhruv Nair](https://github.com/Nair3091):** For the pre-alpha testing and post-release loyalty.
- **[NotCandy001](https://github.com/notcandy001):** For the installer
- **[SiriKedas](https://github.com/sirikedas):** For the new architecture Idea and time.
- **All the Testers & Contributors:** For their time put into testing and suggesting fixes.
  > Brain_Shell has recently been Endorsed by [theyh4t3-ashlxy](https://github.com/theyh4t3-ashlxy).
  > Menace of the Discord Server. They show up, vibe code, complain about the shell, aggressively support it anyway, and somehow keeps the server alive.

---

## Brain Cells Collected

<div align="center">
  <a href="https://www.star-history.com/?repos=Brainitech%2FBrain_Shell&type=date&legend=top-left">
   <picture>
     <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Brainitech/Brain_Shell&type=date&theme=dark&legend=top-left" />
     <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Brainitech/Brain_Shell&type=date&legend=top-left" />
     <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Brainitech/Brain_Shell&type=date&legend=top-left" />
   </picture>
  </a>
</div>

---

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPLv3) – see the [LICENSE](LICENSE) file for details.
