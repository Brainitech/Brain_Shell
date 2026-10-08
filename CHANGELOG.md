# Changelog

All notable changes to Brain_Shell will be documented in this file.

## What's New in v0.2.0

_v0.2.0 basically got the TeamCherry treatment: meaning we rebuilt the entire architecture from the ground up (and yes, it took long enough). Here's what came out of it:_

- **Dynamic Surface Architecture:** Replaced the old individual TopBar/Border/Popup window model with a unified `DynamicSurface` engine - popups now render inline instead of spawning separate Wayland windows

- **Global Animation Engine:** Added 6 new easing curves and animation styles with a live speed multiplier, all configurable from Settings

- **Context-Aware UI Scaling:** Resolved inconsistent sizing across different displays - popups and modules now dynamically calculate their dimensions to scale relative to your active monitor.

- **Notch Mini Player:** Embedded media widget with album art, track info, and playback controls, live inside the notch

- **QuickControl OSD:** Pops out automatically when volume/brightness change via hotkeys

- **Screen Recording & Screenshot Overhaul:** Target selection, audio toggles, framerate selection, selectable backends (wf-recorder, gpu-screen-recorder, wl-screenrec), and a unified Capture tile.

- **System Tray Overhaul:** Native dropdown menus with proper Wayland positioning

- **App Launcher Enhancements:** Native QML desktop entry resolution with frecency-based sorting

- **Clipboard Keyboard Navigation:** Full keyboard navigation: Arrow Up/Down with visual row highlighting, Enter to copy, Delete/Backspace to remove, P to pin/unpin, Escape to close all without touching the mouse

- **Theme & Visuals Studio:** 12 popular theme presets with 5-swatch palette previews, independent text/background color overrides, manual Matugen color override, screen color picker tile, dark/light mode tile, blur and opacity controls

- **Better Updater:** Release-based updates with in-app Patch Notes preview

- **Power Menu:** Full keyboard navigation support via Arrow Up/Down and Enter.

- **OS-Based Icon:** Distro-dependent OS icon in the system menu

- **Performance:** Better resource usage overall

- **Installer Ecosystem Overhaul:** TTY/GUI detection, hardware probing, keybind conflict resolution, and AUR bootstrap fixes

- **First-Class NixOS & Home Manager Integration:**
  - **Unified Path Abstraction Singleton (`Paths.qml`):** Centralized path resolution singleton (`Paths.installDir`, `Paths.configDir`, `Paths.userDataDir`, `Paths.isNix`) supporting `BRAIN_SHELL_*` environment overrides and read-only Nix store detection.
  - **Hermetic Flake Packaging:** Flake package using `makeWrapper` bundling 54 runtime dependencies on `$PATH`.
  - **Portable `brain-shell` CLI Wrapper:** Unified command on `$PATH` for launching the shell and forwarding IPC commands (`brain-shell ipc call <target> toggle`).
  - **Idempotent Runtime Self-Initialization (`init_user_dir.sh`):** Non-destructive first-run seeding of user templates (`hypridle.conf`, `hyprlock.conf`, `matugen.toml`), wallpapers, and JSON configurations into `~/.config/Brain_Shell`.
  - **Declarative Home Manager Module:** Introduced `brain-shell.homeManagerModules.default` with options (`programs.brain-shell.{enable, package, extraPackages, hyprland.enable}`) and declarative Hyprland autostart integration (`exec-once`).
  - **Declarative NixOS Module:** Supported system-level configuration via `brain-shell.nixosModules.default` (`programs.brain-shell.enable = true;`).
  - **Arch Linux Zero-Regression Guarantee:** 100% backward-compatible fallback for existing Arch Linux setups (`~/.local/src/Brain_Shell`, `qs ipc -p ...`, and untouched auto-update).

---

## Notable Fixes

- **Smoother UI:** A brand new dynamic surface architecture eliminates choppy popups and delivers perfectly fluid, unified animations.

- **Better Theme Persistence:** Enhanced theme persistence for Hyprland borders.

- **UI Scaling:** Proper resolution based scaling ensures the sizes look just right.

- **Multi-Monitor Scaling Inconsistency:** Partially resolved via the new `localScale` architecture.

- **Top Bar Clipping:** Resolved by replacing the legacy TopBar with the new DynamicSurface.

- **Shutdown Menu State Issues:** Resolved - power actions now route cleanly through systemctl/loginctl with confirmation dialogs.

- **NixOS & Flakes Support:** Replaced brittle imperative scripts with official, hermetic NixOS and Home Manager flake modules, CLI wrapper forwarding, and automated first-run self-initialization.
