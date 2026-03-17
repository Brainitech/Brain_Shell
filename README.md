# Brain Shell

A modular session shell for Hyprland, built on Quickshell.

## Devlog 5: QuickSettings, Media, and Compositor Polish

**Core Additions**

- **QuickSettings Grid:** Expanded the panel with Do Not Disturb (DND), Airplane Mode, and an inline Brightness slider. (Hotspot is currently under testing; Dark Mode is a UI stub).
- **Dashboard Cards:** \* `ProfileCard`: Now dynamically pulls system uptime, active window manager, and user avatar.
  - `PlayerCard`: MPRIS integration is complete. UI now accurately reflects play/pause states and uses a blurred album art background.
- **Notification Daemon:** `NotificationService` is now DND-aware. Incoming alerts are silently queued without triggering toasts or audio when DND is active.

**Compositor & Rendering Fixes**

- **Focus Mode Fades:** Switched `TopBar` and `Border` hiding mechanics to use opacity fades rather than visibility toggles. This prevents the Wayland compositor from destroying and recreating the surfaces. Focus mode activation and deactivation is now fully wired and functional.
- **Input Masking:** Added mask proxy items to the notch gaps to fix a bug where clicks were passing through transparent areas to background windows.

**Architecture Refactoring**

- **State Extraction:** Moved timer and alarm logic out of the UI and into a dedicated `ClockState.qml` singleton.
- **Service Domains:** Reorganized the backend QML files into strict domain subdirectories (`services/system/`, `services/home/`, `services/notifications/`) to manage growing complexity.

---

## Current Architecture Status

- **Centralized Popups:** `shell.qml` handles the anchor windows, but passes them to `PopupLayer.qml`, which acts as the single source of truth for instantiating all popup windows.
- **Universal Animations:** Slide-in/out and hover-to-open logic are standardized across the shell via `PopupSlide.qml`.
- **State Management:** Local state stays local unless needed elsewhere. Cross-cutting variables (like Airplane Mode) live in `ShellState.qml`.

## Roadmap / Up Next

- **Wallpaper & Theme Manager:** (This will wire up the current Dark Mode QuickSettings stub).
- **Network Popup:** Building the content menu and finalizing the Hotspot toggle logic.
- **CenterNotch Media Pill:** Building a compact, dynamic media island using the existing MPRIS backend.
- **Pending Dashboard Tabs:** Kanban, App Launcher, and Config.
- **Pending Popups:** Battery.
