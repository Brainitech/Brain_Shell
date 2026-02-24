# 🧠 Brain Shell — Devlog

Tracking the active development of my modular, highly customizable session shell built with **Quickshell** and **Hyprland**.

## 🚀 Latest Updates (Devlog 2)

- **Audio is Alive:** `AudioPopup` is no longer a placeholder. It now features a fully functional 3-tab audio panel (Output, Input, Mixer) integrated with Pipewire, including drag-to-scrub volume, mouse-wheel support, and default device selection.
- **Animation & Hover Engine:** Introduced `PopupSlide.qml`, a universal wrapper that standardizes slide-in/out animations and hover-to-open logic across all popups.
- **Centralized Instantiation:** Moved away from scattered window creation. `PopupLayer.qml` is now the single source of truth for all popups, significantly cleaning up `shell.qml`.

## 🏗️ Core Architecture

- **Single Source of Truth:** `shell.qml` creates the anchor windows (TopBar, Borders) and passes them into `PopupLayer.qml`, which handles instantiating all popup elements in one place.
- **Standalone Popups:** Popups live independently in `src/popups/`. They maintain visual consistency through a `Theme` singleton and a shared `PopupShape` canvas, avoiding a bulky generic wrapper.
- **Global State & Timing:** A central `Popups.qml` singleton manages all toggles and global timing configurations (like `slideDuration` and `hoverCloseDelay`), preventing messy prop-drilling.
- **Smart Dismiss Layer:** `PopupDismiss.qml` acts as a transparent fullscreen overlay that cleanly catches clicks to close popups without blocking the TopBar triggers.

## ✅ What's Built (Progress)

- **Custom UI & Layout Components:**
  - `TabSwitcher.qml`: Reusable vertical icon tab column with wheel scroll support.
  - `PopupPage.qml`: Standardized, scrollable popup page container.
  - `PopupShape.qml`: Canvas for the seamless, "melted" edge effect.
- **ArchMenu (`ArchMenu.qml`):** A left-edge popup featuring a dynamic 3-tab layout (Power, Gfx, Stats) with smooth, content-aware dimension animations.
- **Integrated Services:**
  - **AudioControl:** Complete volume and device management for Output, Input, and Mixers.
  - **PowerMenu:** Wired up to `Quickshell.Io.Process` for Shutdown, Reboot, Suspend, and Lock.
  - **SystemStats:** Wraps `fastfetch` and neatly formats the output into styled QML rows.
  - **GfxControl:** Reads power profiles and handles dGPU toggles securely. Intercepts clicks with a `GfxWarning` modal before executing `supergfxctl -m <mode>`.

## 🚧 Known Issues & WIP

- **Missing Popups:** Network, Battery, and Notification popups are stubbed in `PopupLayer` and wired to their bar triggers, but the actual content menus are under construction.
- **Center Bar Layout:** The `CenterContent` carousel is currently static (marked as "Work In Progress"), though active window title and hostname items exist.
- **Hardcoded Sizes:** The `ArchMenu` page dimensions currently rely on estimated hardcoded values instead of truly dynamic sizing based on rendered content.
- **Focus Quirk:** Opening a popup temporarily pulls focus from background apps. This is a known and acceptable trade-off due to the Top Layer dismiss overlay.
