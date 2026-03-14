# 🧠 Brain Shell — Devlog

Tracking the active development of my modular, highly customizable session shell built with **Quickshell** and **Hyprland**.

## 🚀 Latest Updates (Devlog 4)

- **Notification System Complete:** Built a full end-to-end D-Bus notification daemon (`org.freedesktop.Notifications`). Includes a scrollable `NotificationList` popup and transient `NotificationToast` banners for incoming alerts.
- **Dashboard Home Tab:** The core layout is up. Completed the `ProfileCard` (dynamically reads `$USER`), `ClockCard`, `CalendarCard`, and `BrightnessCard` (fully wired to `brightnessctl` with wheel support).
- **System Dashboard Finished:** All hardware panels (CPU, GPU, Disk, Network, Fan) are fully wired and consolidated neatly under `modules/Center/`.
- **Major Refactor & Polish:** Reorganized the flat `services/` directory into domain-specific subdirectories (`home/`, `system/`, `notifications/`). Added a unified `ConfirmDialog` dispatcher, centralized animation durations in `Theme.qml`, and added visual indicators for urgent workspaces.

## 🏗️ Core Architecture

- **Domain-Driven Services:** Backend QML services are categorized by domain (e.g., `services/system/` for hardware monitoring, `services/home/` for dashboard cards) to keep the project highly organized.
- **Local vs. Global State:** Introduced a `ShellState.qml` singleton for cross-cutting states. However, localized states (like WiFi/Bluetooth toggles) deliberately remain self-contained within their respective components to prevent unnecessary hoisting.
- **Single Source of Truth:** `shell.qml` creates the anchor windows (TopBar, Borders) and passes them into `PopupLayer.qml`, which handles instantiating all popup elements in one place.
- **Smart UI Updates:** UI state updates for system-level scripts (like GPU switching via `envycontrol`) rely on capturing `stdout` signaling before `pkexec` finishes, ensuring responsive mid-execution feedback.

## ✅ What's Built (Progress)

<details>
<summary><b>🛠️ UI & Layout Components</b></summary>

- **Data Visualization:** Custom `Speedometer.qml` (canvas arc gauge), `DiskBar.qml` (horizontal usage fill), and `StatCard`/`StatRow` for standardized dashboard metrics.
- **Layouts:** `PopupPage.qml` (scrollable containers) and `TabSwitcher.qml` (vertical icon columns with mouse-wheel support and active/urgent states).
- **Animations:** `PopupSlide.qml` standardizes slide-in/out animations and hover-to-open logic across the shell.
- **Modals:** Refactored `ConfirmDialog.qml` with a unified `showConfirm()` dispatcher for secure action interception.

</details>

<details>
<summary><b>🪟 Popups & Dashboards</b></summary>

- **Dashboard (`Dashboard.qml`):** The expanding notch popup.
  - _System Tab:_ Fully complete (CPU, GPU, Disk, Network, Temps, Fan Control).
  - _Home Tab:_ Functional Profile, Clock, Calendar, and Brightness cards. QuickSettings is partially operational.
- **Notifications:** Top-edge `NotificationsPopup` list and `NotificationToast` banners.
- **ArchMenu:** Dynamic 3-tab left-edge popup (Power, Gfx, Stats).
- **AudioPopup:** Full 3-tab audio panel (Output, Input, Mixer) integrated with Pipewire.

</details>

<details>
<summary><b>⚙️ Backend Services</b></summary>

- **Notifications (`services/notifications/`):** Full D-Bus listener and list manager.
- **System (`services/system/`):** Modular hardware polling for CPU, GPU (plus `EnvyControl`), RAM, Disk, Network, and Thermals.
- **Home (`services/home/`):** Dedicated service cards for dashboard components.
- **Core Controls:** `PowerMenu.qml` (secure session management via `PowerControl.sh`) and `AudioControl.qml`.

</details>

## 🚧 Known Issues & WIP

- **Focus Mode Trap:** The Focus Mode toggle in QuickSettings successfully hides the bar, but currently has no deactivate mechanism/escape hatch, making the UI unreachable once activated.
- **Dashboard Incomplete:** \* `PlayerCard` is UI-only and pending MPRIS integration/redesign.
  - Game Mode toggle is missing from QuickSettings.
  - Kanban, App Launcher, and Config tabs haven't been started.
- **Missing Popups:** Network and Battery popups are stubbed in `PopupLayer` and wired to their bar triggers, but the content menus remain unbuilt.
