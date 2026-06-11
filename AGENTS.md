# AGENTS.md — Brain_Shell

**Project:** Brain_Shell  
**Version:** 0.1.0  
**Framework:** QtQuick / Quickshell  
**Primary Languages:** QML, JavaScript, Python, Bash  
**Compositor:** Hyprland (via `hyprctl`)  
**Target Platforms:** Arch Linux, Fedora, NixOS  

---

## 1. Project Overview

Brain_Shell is a dynamic, highly modular Wayland desktop shell built on [Quickshell](https://git.outfoxxed.me/outfoxxed/quickshell). It provides a top bar with three notches (left, center, right), a popup system (dashboard, audio, network, notifications, clipboard, wallpaper, arch menu), and system services for monitoring, power management, and more.

The shell uses a reactive JSON configuration system (`ShellConfigService`) and supports Material You dynamic colors via `matugen`.

### Key Features
- **Modular bar** — Left/Center/Right notches with independent content
- **Dashboard** — Home, System Stats, Kanban Tasks, App Launcher, Config tabs
- **Popup system** — Audio, Network (WiFi/BT/VPN/Hotspot), Notifications, Clipboard, Wallpaper
- **App Launcher** — Native DesktopEntries fuzzy search with usage tracking
- **System monitoring** — CPU, RAM, GPU, Disk, Thermal, Fan control
- **Unified animations** — `Anim.qml` with standard/emphasized/spatial/spring curves
- **Reusable components** — `StyledRect`, `Surface`, `StateLayer`, `AnimatedBehavior`
- **Standalone CLI** — `cli.sh` provides launch, IPC, install/remove without touching system files
- **Multi-shell coexistence** — Multiple shells can run on the same PC with isolated configs

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI Framework** | Qt 6 (QtQuick, QtQuick.Controls, QtQuick.Layouts) | Rendering, animations, controls |
| **Shell Runtime** | Quickshell (`qs`) | Wayland panel/surface manager, QML engine |
| **Compositor Bridge** | `hyprctl` CLI | Window manager interaction (submaps, gaps, shaders) |
| **Configuration** | JSON on disk + `FileView` | Reactive, file-backed persistent config |
| **Color Generation** | `matugen` | Material You color extraction from wallpapers |
| **Packaging** | Nix Flake (`flake.nix`) | Reproducible builds, dev shells |
| **Install Script** | `install.sh` (Bash) | Arch / Fedora dependency install, Hyprland config |

### Runtime Dependencies
- **Core:** `quickshell`, `qt6-base`, `qt6-declarative`, `qt6-wayland`, `qt6-svg`
- **Compositor:** `hyprland`
- **System:** `brightnessctl`, `upower`, `power-profiles-daemon`, `NetworkManager`, `bluetooth`
- **Media:** `playerctl`, `wf-recorder`, `gpu-screen-recorder`
- **Tools:** `kitty`, `matugen`, `cliphist`, `zenity`, `jq`
- **Fonts:** Nerd Fonts symbols, Phosphor icons (mixed usage currently)

---

## 3. Project Structure

```
./
├── shell.qml                 # Entry point: ShellRoot, Variants per screen
├── install.sh                # Distribution-aware installer
├── flake.nix                 # Nix flake
│
├── src/
│   ├── qmldir                # Singleton + type registrations
│   │
│   ├── theme/                # Theming system
│   │   ├── Theme.qml         # Aggregator: Colors + Metrics → single import
│   │   ├── Colors.qml        # Dynamic color palette from matugen output
│   │   ├── Metrics.qml       # Layout constants (sizes, spacing, radii)
│   │   ├── Anim.qml          # Unified animation system (durations, easing curves)
│   │   └── ColorLoader.qml   # matugen JSON watcher
│   │
│   ├── components/           # Reusable UI primitives
│   │   ├── StyledRect.qml    # Themed rectangle container
│   │   ├── Surface.qml       # Elevated surface (StyledRect + StateLayer)
│   │   ├── StateLayer.qml    # M3 interaction overlay (hover/press/ripple)
│   │   ├── AnimatedBehavior.qml  # Reusable animation behavior
│   │   ├── IconBtn.qml       # Icon button with hover/press feedback
│   │   ├── TabSwitcher.qml   # Horizontal/vertical tab navigation
│   │   ├── PopupPage.qml     # Animated page container with header
│   │   ├── PopupSlide.qml    # Slide-in animation wrapper
│   │   ├── StatCard.qml      # Metric display card
│   │   ├── StatRow.qml       # Horizontal stat bar
│   │   ├── DiskBar.qml       # Disk usage visualization
│   │   ├── Speedometer.qml   # Circular gauge
│   │   ├── TimeInput.qml     # Time input control
│   │   └── ProfileButton.qml # User profile button
│   │
│   ├── shapes/               # Shared shape primitives
│   │   ├── PopupShape.qml    # Rounded rect with attached-edge flare
│   │   └── SeamlessBarShape.qml  # Bar background shape
│   │
│   ├── windows/              # Screen-level PanelWindows
│   │   ├── TopBar.qml        # Main bar (left/center/right notches)
│   │   ├── Border.qml        # Screen border overlays
│   │   ├── PopupDismiss.qml  # Click-outside popup dismissal
│   │   ├── ConfirmDialog.qml # GPU mode change confirmation
│   │   └── UpdatePopup.qml   # Shell update notification
│   │
│   ├── modules/              # Bar content modules
│   │   ├── Center/           # Center notch content (clock, workspace dots)
│   │   ├── Left/             # Left notch content (arch menu trigger)
│   │   └── Right/            # Right notch content (audio, network, battery, notifications triggers)
│   │
│   ├── popups/               # All popup windows
│   │   ├── PopupLayer.qml    # Single instantiation point for all popups
│   │   ├── Dashboard.qml     # Main dashboard with tab navigation
│   │   ├── AudioPopup.qml    # Audio output/input control
│   │   ├── NetworkPopup.qml  # WiFi/Bluetooth/VPN/Hotspot tabs
│   │   ├── NotificationsPopup.qml  # Notification history
│   │   ├── NotificationToast.qml   # Incoming notification toast
│   │   ├── ClipboardPopup.qml      # Clipboard history
│   │   ├── WallpaperPopup.qml      # Wallpaper browser
│   │   ├── ArchMenu.qml      # System menu (power, settings)
│   │   ├── QuickControl.qml  # Quick settings panel
│   │   ├── ScreenRecOptionsPopup.qml  # Screen recording options
│   │   ├── WifiTab.qml       # WiFi network list
│   │   ├── BluetoothTab.qml  # Bluetooth device list
│   │   ├── VPNTab.qml        # VPN connection management
│   │   ├── HotspotTab.qml    # Hotspot configuration
│   │   └── HistoryTab.qml    # Notification history panel
│   │
│   ├── services/             # Backend singletons
│   │   ├── ShellConfigService.qml   # JSON config persistence
│   │   ├── PerMonitorConfig.qml     # Per-monitor overrides
│   │   ├── FocusGrabManager.qml     # Input focus coordination
│   │   ├── AppSearch.qml     # DesktopEntries + fuzzy search
│   │   ├── UsageTracker.qml  # App launch frequency tracking
│   │   ├── AppLauncher.qml   # App launcher UI
│   │   ├── WallpaperService.qml     # Wallpaper management
│   │   ├── ScreenRecService.qml     # Screen recording
│   │   ├── ScreenshotTool.qml       # Screenshot capture
│   │   ├── ClipboardService.qml     # Clipboard history (cliphist)
│   │   ├── CavaService.qml   # Audio visualization
│   │   ├── AudioControl.qml  # PipeWire volume/device control
│   │   ├── BatteryStatus.qml # Battery monitoring
│   │   ├── BatteryWarning.qml# Low battery alert
│   │   ├── UpdateService.qml # Shell update checker
│   │   ├── KanbanBoard.qml   # Task board
│   │   ├── PowerMenu.qml     # Power actions
│   │   ├── home/             # Dashboard home page components
│   │   │   ├── DashHome.qml  # Home layout
│   │   │   ├── QuickSettings.qml  # Toggles + brightness
│   │   │   ├── ClockCard.qml # Date/time display
│   │   │   ├── PlayerCard.qml# Media player
│   │   │   ├── ProfileCard.qml    # User avatar
│   │   │   └── CalendarCard.qml   # Calendar widget
│   │   ├── config_tab/       # Settings UI
│   │   │   ├── ShellConfig.qml    # Shell settings panel
│   │   │   ├── KeybindService.qml # Keybind configuration
│   │   │   └── KeybindsPage.qml   # Keybind UI
│   │   ├── notifications/    # Notification system
│   │   │   ├── NotificationService.qml  # DBus notification server
│   │   │   └── NotificationList.qml     # Notification list component
│   │   └── system/           # Hardware monitors
│   │       ├── SystemStats.qml    # Aggregated stats
│   │       ├── CpuService.qml     # CPU usage
│   │       ├── CpuFreqService.qml # CPU frequency
│   │       ├── MemService.qml     # Memory usage
│   │       ├── GpuService.qml     # GPU stats
│   │       ├── DiskService.qml    # Disk usage
│   │       ├── NetService.qml     # Network throughput
│   │       ├── ThermalService.qml # Temperature sensors
│   │       ├── FanControl.qml     # Fan speed control
│   │       ├── EnvyControl.qml    # NVIDIA Optimus control
│   │       └── EnvyControlService.qml  # GPU mode service
│   │
│   ├── state/                # Global singleton state
│   │   ├── ShellState.qml    # WiFi/BT/DND/focus/hotspot/VPN state + submap control
│   │   ├── Popups.qml        # Per-popup open/close state + universal controls
│   │   ├── ClockState.qml    # Clock formatting state
│   │   └── IpcManager.qml    # IPC message handler
│   │
│   ├── config/               # Static config files
│   │   ├── brain-shell-colors.json.example
│   │   ├── colors.conf.template
│   │   ├── hypridle.conf
│   │   ├── hyprlock.conf
│   │   ├── matugen.toml
│   │   └── shaders/
│   │
│   └── scripts/              # Shell scripts invoked by services
│       ├── GfxSwitch.sh      # GPU mode switching
│       ├── PowerControl.sh   # Power profile control
│       └── colorpicker.py    # Screen color picker
│
├── dots-extra/               # Installer extras
│   ├── install-arch.sh
│   └── validate-install.sh
│
└── assets/                   # Wallpapers and static resources
    └── wallpapers/
```

---

## 4. Build, Run, and Test Commands

### Running Locally
```bash
# Via the CLI wrapper (recommended — standalone, no system edits)
./cli.sh

# Or direct Quickshell launch
qs -p shell.qml

# IPC commands (requires running shell)
./cli.sh run dashboard-home     # Open dashboard on Home tab
./cli.sh run launcher            # Open app launcher
./cli.sh reload                  # Restart the shell
./cli.sh quit                    # Stop the shell

# Hyprland integration
./cli.sh install hyprland        # Add to autostart
./cli.sh remove hyprland         # Remove from autostart
```

### Nix Development Shell
```bash
nix develop
```

### Testing
**There is currently no automated test suite.** The project relies on manual runtime testing on Hyprland.

---

## 5. Runtime Architecture

### Entry Point (`shell.qml`)
1. `ShellRoot` initializes singletons: `KeybindService`, `UpdateService`, `IpcManager`
2. Per-screen `Variants` create: `TopBar`, `Border` (left/right/bottom), `PopupDismiss`, `ConfirmDialog`, `UpdatePopup`
3. `PopupLayer` instantiates all popup windows, receiving anchor window references

### Config Lifecycle
- `ShellConfigService.qml` watches `~/.config/Brain_Shell/src/user_data/shell_config.json`
- Properties: `animationSpeed`, `barEnabled`, `dashboardWidth`, `dashboardHeight`, `focusModeOnStartup`, `autoUpdateCheck`
- Changes auto-persist via `save()`

### Color System
- `ColorLoader.qml` watches `~/.cache/Brain_Shell/colors.json` (generated by `matugen`)
- `Colors.qml` exposes semantic color properties
- `Theme.qml` aggregates `Colors` + `Metrics` for single-import convenience

### Compositor Integration
- `ShellState.qml` manages Hyprland submap switching for keybind interception
- `QuickSettings.qml` reads/writes Hyprland gaps and shader settings
- `WallpaperService.qml` applies active border color to Hyprland
- `ScreenshotTool.qml` and `ScreenRecService.qml` query Hyprland for window/monitor info

---

## 6. Code Organization and Key Symbols

### Singletons (registered in `src/qmldir`)
| Symbol | File | Responsibility |
|--------|------|----------------|
| `Theme` | `src/theme/Theme.qml` | Aggregated Colors + Metrics |
| `Anim` | `src/theme/Anim.qml` | Unified animation system |
| `Popups` | `src/state/Popups.qml` | Popup visibility state |
| `ShellState` | `src/state/ShellState.qml` | System state (WiFi, BT, DND, etc.) |
| `ClockState` | `src/state/ClockState.qml` | Clock formatting |
| `IpcManager` | `src/state/IpcManager.qml` | IPC messages + named pipe reader + unified command dispatcher |
| `ShellConfigService` | `src/services/ShellConfigService.qml` | JSON config persistence |
| `PerMonitorConfig` | `src/services/PerMonitorConfig.qml` | Per-monitor overrides |
| `FocusGrabManager` | `src/services/FocusGrabManager.qml` | Popup focus coordination |
| `AppSearch` | `src/services/AppSearch.qml` | App listing + fuzzy search |
| `UsageTracker` | `src/services/UsageTracker.qml` | App launch tracking |
| `WallpaperService` | `src/services/WallpaperService.qml` | Wallpaper management |
| `ScreenRecService` | `src/services/ScreenRecService.qml` | Screen recording |
| `ScreenshotTool` | `src/services/ScreenshotTool.qml` | Screenshot tool |
| `ClipboardService` | `src/services/ClipboardService.qml` | Clipboard history |
| `CavaService` | `src/services/CavaService.qml` | Audio visualization |
| `KeybindService` | `src/services/config_tab/KeybindService.qml` | Keybind management |
| `UpdateService` | `src/services/UpdateService.qml` | Update checker |
| `NotificationService` | `src/services/notifications/NotificationService.qml` | DBus notification server |

### Component Primitives
| Component | File | Usage |
|-----------|------|-------|
| `StyledRect` | `src/components/StyledRect.qml` | Themed container with gradient/border/shadow support |
| `Surface` | `src/components/Surface.qml` | Elevated surface (StyledRect + StateLayer) |
| `StateLayer` | `src/components/StateLayer.qml` | Hover/press/ripple interaction feedback |
| `AnimatedBehavior` | `src/components/AnimatedBehavior.qml` | Reusable animation Behavior wrapper |
| `IconBtn` | `src/components/IconBtn.qml` | Icon button |
| `TabSwitcher` | `src/components/TabSwitcher.qml` | Tab bar navigation |

---

## 7. Development Conventions

### QML & JavaScript
- **Indentation:** 4 spaces
- **Imports:** Use relative paths. Files at depth 1 use `import "../theme"`; files at depth 2 use `import "../../theme"`
- **Null safety:** Always null-check nested properties
- **Singletons:** Registered in `src/qmldir` with `singleton` keyword
- **Services qmldir:** `src/services/qmldir` provides legacy aliases for some singletons

### Animation System
All UI motion must go through `Anim.qml`:

- **Use `AnimatedBehavior`** for every `Behavior`:
  ```qml
  Behavior on opacity {
      AnimatedBehavior { type: "standard"; size: "normal" }
  }
  ```
  Valid `type` values: `"standard"`, `"emphasized"`, `"spatial"`, `"spring"`  
  Valid `size` values: `"small"`, `"normal"`, `"large"`, `"extraLarge"` (standard); `"fast"`, `"default"`, `"slow"` (spatial); `"small"`, `"normal"`, `"large"` (emphasized/spring)

- **When `AnimatedBehavior` is not enough**, use `Anim.duration(type, size)` and `Anim.easing(name)`:
  ```qml
  NumberAnimation {
      duration: Anim.duration("standard", "normal")
      easing.type: Anim.easing("standard").type
      easing.bezierCurve: Anim.easing("standard").bezierCurve
  }
  ```

- **Convenience properties** available directly on `Anim`:
  - `Anim.standardNormal`, `Anim.standardLarge`, etc.

### Color Resolution
- Never hardcode colors. Use `Theme.background`, `Theme.text`, `Theme.active`, etc.
- `Theme` aggregates both `Colors` and `Metrics` for convenience

### Anti-Patterns (Strictly Avoid)
1. **Hardcoding colors, sizes, or durations** — Use `Theme.*`, `Anim.*`
2. **Using `Qt.rgba()` for structural colors** — Use `Theme.*` or `StyledRect` variants
3. **Creating raw `Rectangle` containers** — Use `StyledRect` or `Surface`
4. **Animation bypass** — Never use raw `Easing.OutCubic` or hardcoded durations
5. **Missing popup transitions** — All popups must animate open/close with opacity + scale/size
6. **`Qt.createQmlObject('Process { }', ...)`** — Prefer declarative `Process {}` where possible
7. **`Metrics.animDuration`** — Removed. Use `Anim.*` instead

---

## 8. Where to Look for Common Tasks

| Task | Primary Location | Notes |
|------|------------------|-------|
| **Add config key** | `src/services/ShellConfigService.qml` | Add property + parse + save |
| **Change bar layout** | `src/windows/TopBar.qml` | Bar sizing, notch arrangement |
| **Add popup** | `src/popups/PopupLayer.qml` | Single instantiation point |
| **Theme / colors** | `src/theme/Colors.qml`, `src/theme/Theme.qml` | Watches `~/.cache/Brain_Shell/colors.json` |
| **Animations** | `src/theme/Anim.qml` | Standard / Emphasized / Spatial / Spring curves |
| **System monitoring** | `src/services/system/` | CPU, RAM, GPU, Disk, Thermal, Fan |
| **Notifications** | `src/services/notifications/NotificationService.qml` | DBus `NotificationServer` |
| **Clipboard** | `src/services/ClipboardService.qml` | cliphist wrapper |
| **Lockscreen config** | `src/config/hyprlock.conf` | Hyprlock theme |
| **Screenshots** | `src/services/ScreenshotTool.qml` | Uses grim/slurp |
| **Screen recording** | `src/services/ScreenRecService.qml` | Uses wf-recorder / gpu-screen-recorder |
| **Dashboard pages** | `src/services/home/`, `src/services/system/`, `src/services/KanbanBoard.qml` | Tab content |
| **Settings UI** | `src/services/config_tab/` | Shell config + keybinds |

---

## 9. Known Issues & Planned Work

See the project's internal task tracker for the complete list. Key areas:

- **Dashboard StackView** — Currently uses `visible: root.page === "x"` pattern; planned migration to `StackView` with push/pop and animated transitions
- **HyprlandService** — Multiple files contain scattered `hyprctl` calls; planned centralization into a single typed singleton
- **Notification actions** — Action buttons from DBus notifications are not rendered yet
- **StyledRect/StateLayer consistency** — Some popups still use raw `Rectangle` + `Qt.rgba()` instead of component primitives
- **Typography system** — Font sizes are hardcoded in many places; planned `Theme.fontSize()` system
- **Icon unification** — Mixed usage of Nerd Fonts and Phosphor icons
