# Brain Shell

A modular session shell for Hyprland, built on Quickshell.

## Devlog 6: Wallpaper Picker and Live Matugen Theming

**Core Additions**

- **Wallpaper Picker Popup:** Added a bottom-anchored panel featuring a horizontal thumbnail filmstrip, search bar, folder switcher, and nested scheme picker.
- **Live Matugen Theming:** Picking a wallpaper triggers `swww` and `matugen`, instantly recoloring the entire shell live via a `colors.json` file watcher without requiring a restart.
- **Dashboard Refinements:** Redesigned the clock into a diagonal staircase format and migrated `PlayerCard` and `ClockCard` to use dynamic theme accent colors instead of hardcoded values.

**Compositor & Rendering Fixes**

- **Wayland Keyboard Focus:** Switched the wallpaper popup from `PopupWindow` to a `PanelWindow` with `WlrKeyboardFocus.OnDemand` so the search `TextInput` properly receives keyboard events.
- **Canvas Repaint Triggers:** Fixed a bug where `Border` and timer canvases wouldn't update on theme change by explicitly wiring them to call `requestPaint()` when color properties shift.
- **Animation Artifacts:** Applied a `Region` mask to the wallpaper popup to eliminate visual strip artifacts that appeared during the expand animation.

**Architecture Refactoring**

- **ColorLoader Pipeline:** Created `ColorLoader.qml` as a plain type instantiated inside `Theme.qml` to handle file watching. This cleanly prevents circular dependency crashes between singletons.
- **Wallpaper Service:** Abstracted the entire wallpaper state, `find` operations, and bash command chains into a dedicated `WallpaperService.qml` singleton.

---

## Current Architecture Status

- **Centralized Popups:** `shell.qml` handles the anchor windows, but passes them to `PopupLayer.qml`, which acts as the single source of truth for instantiating all popup windows.
- **Universal Animations:** Slide-in/out and hover-to-open logic are standardized across the shell via `PopupSlide.qml`.
- **State Management:** Local state stays local unless needed elsewhere. Cross-cutting variables live in `ShellState.qml`, and theme variables stream dynamically through `Theme.qml` via the `ColorLoader` watcher.

## Roadmap / Up Next

- **CenterNotch Media Pill:** Building a compact, dynamic media island using the existing MPRIS backend.
- **Network Popup:** Building the content menu and finalizing the Hotspot toggle logic.
- **Dark Mode Wiring:** Connecting the QuickSettings placeholder now that the theming pipeline is live.
- **Pending Dashboard Tabs:** Kanban, App Launcher, and Config.
- **Pending Popups:** System Tray, Network, Connections
