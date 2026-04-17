# Brain Shell

A modular session shell for Hyprland, built on Quickshell.

## Devlog 8: Network Popup, Dashboard Apps, and Massive Bug Squashing

**Core Additions**

- **Network Popup:** Built a fully functional three-tab panel covering Wi-Fi, Bluetooth, and VPN (WireGuard). Features include inline password entry requiring `WlrKeyboardFocus.OnDemand`, a pulsating `ScanRings` animation during scans, and interactive Bluetooth pairing via a `bluetoothctl` stdin pipe.
- **Kanban Board:** The Kanban dashboard tab is now fully wired, fixing an input focus bug and saving state persistently.
- **App Launcher:** Added a new dashboard tab that runs `list_apps.py` to parse installed `.desktop` files, resolve icon themes, and launch applications as detached processes.

**Compositor & Rendering Fixes**

- **Dashboard Masking:** Corrected the mask proxy geometry to eliminate a dead zone at the notch-to-panel junction, ensuring the click-to-close behavior works accurately.
- **Notification Alignment:** Unified the widths of notification toasts and the list popup through `Theme` constants to prevent visual misalignment when both are active.
- **TopBar Margin:** Resolved a stale top margin that was causing a one-pixel gap between the bar and the screen edge on certain compositor setups.

**Architecture Refactoring**

- **User Data Consolidation:** Moved `tasks.json`, `wallpaper.json`, and `screenrec.json` from scattered config paths into a unified `src/user_data/` directory to cleanly manage runtime-mutable data.
- **QuickSettings Synchronization:** Fixed a race condition where rapid toggling caused state desyncs against in-flight commands. The Dark Mode toggle is now fully implemented, updating Matugen, `gsettings`, and GTK 3/4 settings simultaneously.
- **Widget Polish:** Added a Cava source selector to `PlayerCard` and refactored its bar rendering to remove rounding artifacts. Implemented a midnight rollover timer fix for the `CalendarCard` and added a smooth scaling animation for selected tiles in the wallpaper picker.

---

## Current Architecture Status

- **Centralized Popups:** `shell.qml` handles the anchor windows, but passes them to `PopupLayer.qml`, which acts as the single source of truth for instantiating all popup windows.
- **Universal Animations:** Slide-in/out and hover-to-open logic are standardized across the shell via `PopupSlide.qml`.
- **State Management:** Local state stays local unless needed elsewhere. Cross-cutting variables live in `ShellState.qml`, and theme variables stream dynamically through `Theme.qml` via the `ColorLoader` watcher.

## Roadmap / Up Next

- **Dashboard Config Tab:** Currently a placeholder, slated for post-completion scope.
- **App Launcher Enhancements:** Adding a pinned or recent applications row to supplement the current search-only grid.
