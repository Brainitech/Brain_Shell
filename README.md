  <h3 align="center">
   A modular session shell for Hyprland, built on Quickshell
  </h3>
</p>

<p align="center">
  <img src="https://img.shields.io/github/last-commit/Brainitech/Brain_Shell?&style=for-the-badge&color=8D748C&logoColor=D9E0EE&labelColor=252733" />
  <img src="https://img.shields.io/github/stars/Brainitech/Brain_Shell?style=for-the-badge&logo=starship&color=AB6C6A&logoColor=D9E0EE&labelColor=252733" />
  <img src="https://img.shields.io/badge/version-0.1.0-8D748C?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" />
  <br>
  <img src="https://img.shields.io/badge/hyprland-v0.55+-5E81AC?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" />
  <img src="https://img.shields.io/badge/quickshell-framework-A1C999?style=for-the-badge&logoColor=D9E0EE&labelColor=252733" />
  <br>
  <a href="https://github.com/Brainitech/Brain_Shell/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Brainitech/Brain_Shell?style=for-the-badge&color=A1C999&logo=opensourceinitiative&logoColor=D9E0EE&labelColor=252733" />
  </a>
  <a href="https://github.com/Brainitech/Brain_Shell/issues">
    <img src="https://img.shields.io/github/issues/Brainitech/Brain_Shell?style=for-the-badge&logo=bilibili&color=5E81AC&logoColor=D9E0EE&labelColor=252733" />
  </a>
</p>

---

<h2 align="center">✨ Features</h2>

- **Modular Architecture** — Pick and choose what you need
- **Material You Integration** — Dynamic colors via Matugen
- **Lua-Based Config** — Hyprland v0.55+ compatible
- **System Dashboard** — Monitor CPU, RAM, battery, temps, and more
- **Keybind Editor** — Configure shortcuts in-shell with live conflict detection
- **Theming Engine** — Live wallpaper-synced color updates
- **Network Manager** — WiFi, Bluetooth, VPN integration
- **Audio Control** — PipeWire volume & device management
- **Screen Recorder** — Built-in recording with wf-recorder
- **Clipboard Manager** — Cliphist integration for history management
- **Highly Customizable** — QML-based UI, easily extended

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Package.png" width="25" height="25" />
  </sub>
  Installation
</h2>


### One line installer 
```bash
curl -fsSL https://raw.githubusercontent.com/Brainitech/Brain_Shell/refs/heads/main/install.sh | bash
```

### Manual installation
```bash
git clone https://github.com/Brainitech/Brain_Shell.git
cd Brain_Shell
./install.sh
```

The installer automatically:
- ✓ Detects your Linux distribution
- ✓ Backs up your entire `~/.config`
- ✓ Installs all required dependencies
- ✓ Clones the repository to `~/.local/src/Brain_Shell`
- ✓ Updates your Hyprland config
- ✓ Creates configuration directories

**After installation, restart Hyprland for changes to take effect.**

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Clipboard.png" width="25" height="25" />
  </sub>
  Requirements
</h2>

> [!IMPORTANT]
> **Matugen is required** for dynamic color generation. Brain Shell will not function correctly without it.

### Core Dependencies

<details open>
<summary><b>🖥️ Runtime & Rendering</b></summary>

- **Hyprland** v0.55+ – Wayland compositor
- **Quickshell** – QML shell framework
- **Qt6** – Qt6 libraries and QML engine
- **qt6ct** – Qt6 theme configuration

</details>

<details open>
<summary><b>🔧 System Tools</b></summary>

- **PipeWire** – Audio server (pipewire, pipewire-pulse, wireplumber)
- **NetworkManager** – Network management
- **BlueZ** – Bluetooth stack (bluez, bluez-utils)
- **Brightnessctl** – Backlight control
- **UPower** – Battery and power info
- **libnotify** – Desktop notifications
- **Polkit** – Privilege escalation
- **wl-clipboard** – Wayland clipboard (wl-copy/wl-paste)

</details>

<details open>
<summary><b>🎨 Theming & Wallpaper</b></summary>

- **Matugen** – Material You color generation **(REQUIRED)**
- **awww** – Wallpaper daemon (Wayland)
- **ImageMagick** – Image manipulation

</details>

<details open>
<summary><b>🎬 Recording & Utilities</b></summary>

- **wf-recorder** – Screen recording (Wayland)
- **cava** – Audio visualizer
- **slurp** – Region/window selection
- **wtype** – Keyboard input emulation
- **cliphist** – Clipboard history manager

</details>

<details open>
<summary><b>⚙️ Hardware Management</b></summary>

- **lm_sensors** – CPU temperature & fan monitoring
- **rfkill** – Airplane mode control
- **envycontrol** – GPU switching (NVIDIA/Intel)
- **auto-cpufreq** – CPU frequency scaling
- **nbfc-linux** – Laptop fan control

</details>

<details open>
<summary><b>🔒 Hyprland Integration</b></summary>

- **hyprlock** – Lock screen
- **hypridle** – Idle management daemon
- **hyprsunset** – Blue light filter
- **hyprshutdown** – Graceful shutdown
- **xdg-desktop-portal-hyprland** – Portal backend

</details>

<details open>
<summary><b>🎯 Fonts</b></summary>

- **ttf-jetbrains-mono-nerd** – Primary font (Nerd Font variant)
- **ttf-noto-nerd** – Emoji and CJK support

</details>

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png" alt="Rocket" width="25" height="25" />
  </sub>
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

### Upcoming (Post-v0.1.0)
- [ ] Auto-update mechanism
- [ ] Additional theme options
- [ ] App launcher enhancements (pinned/recent)
- [ ] Unified popup configuration layer
- [ ] Extended documentation
- [ ] Community themes
- [ ] More Linux distribution support

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Hammer.png" width="25" height="25" />
  </sub>
  Architecture & Recent Changes
</h2>

### Devlog 10 Highlights

**Core Additions**
- Keybind Editor with in-shell capture and live conflict detection
- Dynamic Lua config generation with automatic reload
- IPC dispatcher integration for keybind execution

**Architecture Updates**
- Hyprland Lua migration (v0.55+ API)
- Screen recorder backend switched to wf-recorder
- Shader system decoupled from hyprshade

**Bug Fixes & Polish**
- Fixed notification re-firing on reload
- Network panel improvements (password visibility toggle, special character handling)
- Improved dashboard focus management

### Design Philosophy

- **Modular** – Components are self-contained and composable
- **Reactive** – State flows through well-defined channels (ShellState, Theme, ColorLoader)
- **Centralized** – Popups managed by PopupLayer, animations standardized via PopupSlide
- **User-Friendly** – Settings live in-shell, backups automatic, config untouched

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Man%20Technologist.png" width="25" height="25" />
  </sub>
  Contributing
</h2>

Brain Shell is actively developed and welcomes contributions!

- Found a bug? → [Open an issue](https://github.com/Brainitech/Brain_Shell/issues)
- Have an idea? → [Start a discussion](https://github.com/Brainitech/Brain_Shell/discussions)
- Want to contribute? → Fork, branch, and submit a pull request

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Folded%20Hands.png" width="25" height="25" />
  </sub>
  Special Thanks
</h2>

- **[Hyprland Community](https://github.com/hyprwm)** – For creating an exceptional Wayland compositor and fostering an amazing community
- **[Quickshell Contributors](https://github.com/quickshell/quickshell)** – For the powerful QML framework that powers this shell
- **[Matugen Team](https://github.com/InioX/matugen)** – For Material You color generation technology
- **[Wayland Project](https://wayland.freedesktop.org)** – For the modern display protocol foundation

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Memo.png" width="25" height="25" />
  </sub>
  License
</h2>

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
