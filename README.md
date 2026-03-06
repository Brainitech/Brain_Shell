# 🧠 Brain Shell — Devlog

Tracking the active development of my modular, highly customizable session shell built with **Quickshell** and **Hyprland**.

## 🚀 Latest Updates (Devlog 3)

- **Hardware Dashboard is Live:** The System/Stats page of the Dashboard is fully wired. Built a massive suite of new modular services (`CpuService`, `GpuService`, `MemService`, `DiskService`, `NetService`, `ThermalService`) to feed live metrics into the new `TempPanel.qml`.
- **Fan & GPU Control:** Integrated fan speed monitoring and control directly into the dashboard UI. Completely refactored the GPU switcher to use `envycontrol` (via `EnvyControlService` + `GfxSwitch.sh`), routing it safely through an updated `ConfirmDialog`.
- **Massive UX Polish:** * `PopupDismiss` now smartly closes all popups on *workspace switch\*—no more orphaned menus floating around.
  - Added reset functionality to `TabSwitcher` and `AudioControl`.
  - Implemented scroll cooldowns and updated scroll directions for better feel.
  - Added urgent workspace indications and visual effects.
- **Power & Layout:** Added a basic `LayoutDisplayer` to the center module and fully integrated `PowerControl.sh` into the PowerMenu (now supporting proper logout alongside shutdown/reboot).

## 🏗️ Core Architecture

- **Modular Service Backend:** Instead of a monolithic polling script, hardware monitoring is split into dedicated, single-responsibility QML services (CPU, GPU, RAM, Disk, Net, Thermals) that cleanly expose bindable properties to the UI.
- **Single Source of Truth:** `shell.qml` creates the anchor windows (TopBar, Borders) and passes them into `PopupLayer.qml`, which handles instantiating all popup elements in one place.
- **Standalone Popups:** Popups live independently in `src/popups/`. They maintain visual consistency through a `Theme` singleton and a shared `PopupShape` canvas, avoiding a bulky generic wrapper.
- **Global State & Timing:** A central `Popups.qml` singleton manages all toggles and global timing configurations, preventing messy prop-drilling.

## ✅ What's Built (Progress)

- **Custom UI & Layout Components:**
  - `TempPanel.qml`: Dashboard panel displaying live CPU/GPU temps and fan speeds.
  - `TabSwitcher.qml` & `PopupPage.qml`: Reusable scrollable tab columns and pages (recently updated with layout height fixes and accent bar tweaks).
  - `ConfirmDialog.qml`: Secure modal intercept for destructive or system-level actions (like GPU switching).
- **Dashboard (`Dashboard.qml`):** The expanding notch popup is active, defaulting to the Home page, with a fully functional System page.
- **Integrated Services:**
  - **AudioControl:** Complete volume and device management for Output, Input, and Mixers.
  - **System Stats:** Live hardware metrics (CPU freq/usage, GPU VRAM/power, Mem, Disk, Net) backing the dashboard.
  - **PowerMenu:** Wired securely to `PowerControl.sh` for session management.

## 🚧 Known Issues & WIP

- **Dashboard Incomplete:** The System stats page is done, but the Home, Kanban, App Launcher, and Config tabs are currently placeholders.
- **Missing Popups:** Network, Battery, and Notification popups are stubbed in `PopupLayer` and wired to their bar triggers, but the actual content menus remain unbuilt.
- **Center Bar Layout:** The `LayoutDisplayer` module is currently very basic and not in its final state.
