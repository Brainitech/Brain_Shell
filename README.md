  <h1 align=center>Brain_Shell</h1>
  
  <h3 align="center">
  A dynamic, highly modular Wayland desktop shell built with Quickshell and QML, tailored for Hyprland.
  </h3>
</p>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/Brainitech/Brain_Shell?style=for-the-badge&color=8D748C&logoColor=D9E0EE&labelColor=252733" alt="Last Commit" />
  <img src="https://img.shields.io/github/stars/Brainitech/Brain_Shell?style=for-the-badge&logo=starship&color=AB6C6A&logoColor=D9E0EE&labelColor=252733" alt="Stars" />
  <img src="https://img.shields.io/badge/version-0.1.0-8D748C?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Version 0.1.0" />
  <br>
  <img src="https://img.shields.io/badge/hyprland-v0.55+-5E81AC?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Hyprland v0.55+" />
  <img src="https://img.shields.io/badge/quickshell-framework-A1C999?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" alt="Quickshell Framework" />
  <br>
  <a href="https://github.com/Brainitech/Brain_Shell/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Brainitech/Brain_Shell?style=for-the-badge&color=A1C999&logo=opensourceinitiative&logoColor=D9E0EE&labelColor=252733" alt="License" />
  </a>
  <a href="https://github.com/Brainitech/Brain_Shell/issues">
    <img src="https://img.shields.io/github/issues/Brainitech/Brain_Shell?style=for-the-badge&logo=github&color=5E81AC&logoColor=D9E0EE&labelColor=252733" alt="Issues" />
  </a>
  <a href="https://discord.gg/BV8UduvABx">
    <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FBV8UduvABx%3Fwith_counts%3Dtrue&query=approximate_member_count&style=for-the-badge&logo=discord&logoColor=ffffff&label=discord&labelColor=101418&color=96f1f1" alt="Discord Invite" />
  </a>
</p>

---

<h2>Showcase</h2>

<div align="center">
  <video src="https://github.com/user-attachments/assets/93a0697e-c531-4510-b2f0-a59a4b6072b4" controls="controls" muted="muted" style="max-width: 100%; height: auto;"></video>
</div>

---

<h2 align="center">Features</h2>

- **Modular Setup** — Unintrusive setup
- **Material You Integration** — Dynamic colors via Matugen
- **Lua-Based Config** — Hyprland v0.55+ compatible
- **System Dashboard** — Monitor CPU, RAM, battery, temps, and more
- **Kanban/Tasks** — To Do, Ongoing and Competed lists with Prioiry and Deadlines
- **App Launcher** — Native fuzzy search with usage-based ranking
- **Screenshot Tool** — Built-in capture with region/window/screen modes
- **Color Picker** — Screen color sampler
- **Keybinds** — Set your own keybinds for each popup
- **Theming Engine** — Live wallpaper-synced color updates
- **Network Manager** — WiFi, Bluetooth, VPN integration
- **Notifications** — DBus Notifcations via libnotify
- **Audio Control** — PipeWire volume & device management
- **Screen Recorder** — Built-in recording with wf-recorder
- **Clipboard Manager** — Cliphist integration for history management
- **Highly Customizable** — QML-based UI, easily extended

> **Note:** Brain Shell is currently in its `v0.1.0` release. While the core architecture and theming pipeline are feature-complete, you may encounter bugs. Please report them on our [Discord](https://discord.gg/BV8UduvABx) or via GitHub Issues!

---

<h2>
  Installation
</h2>

### One line installer

```bash
curl -fsSL https://raw.githubusercontent.com/Brainitech/Brain_Shell/main/install.sh | bash
```

### What the installer does

- ✓ Clones the repo to `~/.local/src/Brain_Shell`
- ✓ Creates global `brain-shell` command (symlink to `/usr/local/bin`)
- ✓ Adds Brain_Shell to Hyprland autostart
- ✓ Nothing else is touched — fully standalone

**After install, just type:** `brain-shell`

---

### Standalone CLI (No System Modifications)

Brain_Shell ships with a standalone CLI that lets you run and manage the shell **without touching any system files**. Multiple shells can coexist on the same PC — each with its own isolated configuration.

```bash
# Clone and run — no install needed
git clone https://github.com/Brainitech/Brain_Shell.git
cd Brain_Shell
./cli.sh

# IPC commands (requires running shell)
./cli.sh run dashboard-home     # Open dashboard on Home tab
./cli.sh run launcher           # Open app launcher
./cli.sh run screenshot         # Take a region screenshot
./cli.sh run color-picker       # Pick a color from screen

# Manage the shell
./cli.sh reload                 # Restart the shell
./cli.sh quit                   # Stop the shell
./cli.sh lock                   # Lock the screen
./cli.sh update                 # Git pull + restart

# Hyprland autostart (optional)
./cli.sh install hyprland       # Add to Hyprland autostart
./cli.sh install hyprland --lua # For Hyprland ≥0.48 with Lua config
./cli.sh remove hyprland        # Remove from autostart

# Help
./cli.sh help                   # Show all commands
./cli.sh version                # Show version
```

> **Tip:** Symlink `cli.sh` to your PATH for global access:  
> `sudo ln -s $(pwd)/cli.sh /usr/local/bin/brain-shell`

The installer automatically:

- ✓ Detects your Linux distribution
- ✓ Detects your Window Manager and Hyprland Config
- ✓ Backs up your entire `~/.config`
- ✓ Installs all required dependencies
- ✓ Clones the repository to `~/.local/src/Brain_Shell`
- ✓ Updates your Hyprland config to auto-start Brain_Shell and required dependencies
- ✓ Creates configuration directories

**After installation, restart Hyprland for changes to take effect.**

---

<h2>
  Requirements
</h2>

> [!IMPORTANT]
> **Matugen is required** for dynamic color generation. Brain Shell will not function correctly without it.

### Core Dependencies

<details open>
<summary><b>Runtime & Rendering</b></summary>

- **Hyprland** v0.55+ – Wayland compositor
- **Quickshell** – QML shell framework
- **Qt6** – Qt6 libraries and QML engine
- **qt6ct** – Qt6 theme configuration

</details>

<details open>
<summary><b>System Tools</b></summary>

- **PipeWire** – Audio server (pipewire, pipewire-pulse, wireplumber)
- **NetworkManager** – Network management
- **BlueZ** – Bluetooth stack (bluez, bluez-utils)
- **Brightnessctl** – Backlight control
- **Mpris** – Media Retrival
- **Playerctl** – Player controls
- **UPower** – Battery and power info
- **libnotify** – Desktop notifications
- **Polkit** – Privilege escalation
- **wl-clipboard** – Wayland clipboard (wl-copy/wl-paste)

</details>

<details open>
<summary><b>Theming & Wallpaper</b></summary>

- **Matugen** – Material You color generation **(REQUIRED)**
- **awww** – Wallpaper daemon (Wayland)
- **ImageMagick** – Image manipulation

</details>

<details open>
<summary><b>Recording & Utilities</b></summary>

- **wf-recorder** – Screen recording (Wayland)
- **cava** – Audio visualizer
- **slurp** – Region/window selection
- **wtype** – Keyboard input emulation
- **cliphist** – Clipboard history manager

</details>

<details open>
<summary><b>Hardware Management</b></summary>

- **lm_sensors** – CPU temperature & fan monitoring
- **rfkill** – Airplane mode control
- **envycontrol** – GPU switching (NVIDIA/Intel)
- **auto-cpufreq** – CPU frequency scaling
- **nbfc-linux** – Laptop fan control

</details>

<details open>
<summary><b>Hyprland Integration</b></summary>

- **hyprlock** – Lock screen
- **hypridle** – Idle management daemon
- **hyprsunset** – Blue light filter
- **hyprshutdown** – Graceful shutdown
- **xdg-desktop-portal-hyprland** – Portal backend

</details>

<details open>
<summary><b>Fonts</b></summary>

- **ttf-jetbrains-mono-nerd** – Primary font (Nerd Font variant)
- **ttf-noto-nerd** – Emoji and CJK support

</details>

---

<h2>
  Roadmap
</h2>

### Current (v0.1.0)

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
- [x] Auto-update mechanism
- [x] Native app launcher with fuzzy search
- [x] Screenshot tool (region/window/screen)
- [x] Color picker
- [x] Unified animation system
- [x] Reusable UI components (StyledRect, Surface, StateLayer)

### Upcoming (Post-v0.1.0)

- [ ] Scaling on Different Screen-Sizes
- [x] Config Pages for Shell Customization
- [x] Multi-Monitor Support
- [ ] Additional theme options
- [x] App launcher enhancements (pinned/recent)
- [ ] Unified popup configuration layer
- [x] Extended documentation
- [ ] Community themes
- [x] CLI
- [x] More Linux distribution support (Fedora, Debian)

---

<h2>
Known Issues
</h2>

- **Multi-Monitor Scaling:** Global scaling across mixed-resolution monitors (e.g., 4K paired with 1080p) is currently inconsistent. UI elements may appear misproportioned or poorly sized on non-1080p screens.

- **Shutdown Menu (Hyprshutdown) State:** Canceling a shutdown or logout action can sometimes leave the Hyprland session in an empty state with most applications unintentionally closed. It may also occasionally struggle to terminate all running apps smoothly.

---

<h2>
  Contributing
</h2>

Brain Shell is actively developed and welcomes contributions!

- Found a bug? → [Open an issue](https://github.com/Brainitech/Brain_Shell/issues)
- Have an idea? → [Start a discussion](https://github.com/Brainitech/Brain_Shell/discussions)
- Want to contribute? → Fork, branch, and submit a pull request
- Want to join the community? → [Join Discord](https://discord.com/invite/BV8UduvABx)

---

<h2>
  Special Thanks
</h2>

- **[Hyprland Community](https://github.com/hyprwm)** – For creating an exceptional Wayland compositor and fostering an amazing community
- **[Quickshell Contributors](https://github.com/quickshell/quickshell)** – For the powerful QML framework that powers this shell
- **[Matugen Team](https://github.com/InioX/matugen)** – For Material You color generation technology
- **[Wayland Project](https://wayland.freedesktop.org)** – For the modern display protocol foundation
- **[Celestial Shell](https://github.com/caelestia-dots/shell)** & **[AX-Shell](https://github.com/Axenide/ax-shell)** — For the inspiration
- **[NotCandy001](https://github.com/notcandy001)** — For the installer
- **All the Testers & Contributors** — For their time put into testing and suggesting fixes.

---
<h2>
  Brain Cells Collected
</h2>

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

<h2>
  License
</h2>

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
