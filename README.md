# 🧠 Brain Shell — Devlog

Tracking the active development of my Quickshell + Hyprland setup.

## 🏗️ Core Architecture (Done)

- **Standalone Popups:** Popups live in `src/popups/` as independent files rather than a single bulky wrapper. They maintain visual consistency through a `Theme` singleton and a shared `PopupShape`.
- **Global State:** A central `Popups.qml` singleton manages all toggles, preventing messy prop-drilling across files.
- **Smart Dismiss Layer:** Implemented `PopupDismiss.qml`, a transparent fullscreen overlay that cleanly catches clicks to close popups without blocking the TopBar.

## ✅ What's Built (Progress)

- **Custom UI Components:** \* `PopupShape.qml` for that seamless, "melted" edge canvas effect.
  - `GfxWarning.qml` as a safe, fullscreen confirmation modal before switching GPU modes.
- **ArchMenu (`ArchMenu.qml`):** A fully functioning left-edge popup featuring a dynamic 3-tab layout with smooth dimension animations.
- **Integrated Services:**
  - **PowerMenu:** Wired up to `Quickshell.Io.Process` for Shutdown, Reboot, Suspend, Lock, and Logout.
  - **SystemStats:** Wraps `fastfetch` and cleanly formats the output into QML rows.
  - **GfxControl:** Reads active power profiles and handles the dGPU toggle (routing through the `GfxWarning` modal before executing `supergfxctl`).
- **Audio Controls:** Temporary functional feature added to Volume model in `AudioPopup`

## 🚧 What's Missing / WIP

- **Missing Popups:** The bar buttons exist for Network, Battery, and Notifications, but the actual popup menus haven't been built yet.
- **Hardcoded Sizes:** The `ArchMenu` page dimensions currently rely on estimated hardcoded values instead of truly dynamic sizing.
- **Focus Quirk:** Opening a popup temporarily pulls focus from background apps. This is a known trade-off due to the Top Layer dismiss overlay and is acceptable for now.
