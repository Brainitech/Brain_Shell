# Brain Shell

A modular session shell for Hyprland, built on Quickshell.

## Devlog 7: Dynamic Pill, Screen Recording, and Filters

**Core Additions**

- **Dynamic Center Pill:** The center notch carousel now reactively builds its item list based on active shell state. It smoothly scrolls between active media (via MPRIS), running timers, and the active window title.
- **Screen Recording Engine:** Built a complete recording lifecycle via `ScreenRecService.qml`. It supports Screen, Window, and Region captures (using `slurp` ) with configurable audio sources. Settings are persisted across reloads via `screenrec.json`.
- **Screen Rec Options Popup:** Added a dedicated options UI that appears when starting a recording, featuring dropdowns for capture targets, a mirrored Cava visualization, an elapsed timer, and Stop/Discard controls.
- **Filters QuickSetting:** Added a new Filters toggle to the QuickSettings grid. It features a nested shader picker popup that lists and applies available Hyprland screen shaders live via `hyprctl`.

**Compositor & Rendering Fixes**

- **Global Popup State Bug:** Removed `notificationToastOpen` from the global `anyOpen` state. This fixes a critical bug where transient notification toasts were triggering the global dismiss overlay and blocking desktop interactions.
- **Notch Anchoring & Expansion:** Fixed the notification toast anchor position to prevent overlap with the right notch, and corrected the left notch so it no longer erroneously expands when a toast appears.

**Architecture Refactoring**

- **Wallpaper Service Migration:** Updated the wallpaper apply pipeline to use `awww` instead of `swww` following the upstream package rename, restoring live matugen recoloring.
- **Dynamic Paths:** Updated the avatar path in `DashHome.qml` to resolve dynamically via `$HOME`, ensuring the shell remains portable across different user accounts without hardcoding paths.

---

## Current Architecture Status

- **Centralized Popups:** `shell.qml` handles the anchor windows, but passes them to `PopupLayer.qml`, which acts as the single source of truth for instantiating all popup windows.
- **Universal Animations:** Slide-in/out and hover-to-open logic are standardized across the shell via `PopupSlide.qml`.
- **State Management:** Local state stays local unless needed elsewhere. Cross-cutting variables live in `ShellState.qml`, and theme variables stream dynamically through `Theme.qml` via the `ColorLoader` watcher.

## Roadmap / Up Next

- **Network Popup:** Building the full WiFi management panel (connection list, signal strength, password entry) and finalizing the QuickSettings Hotspot toggle.
- **Dark Mode Wiring:** Connecting the QuickSettings placeholder.
- **Pending Dashboard Tabs:** Kanban, App Launcher, and Config.
- **Pending Popups:** Battery.
