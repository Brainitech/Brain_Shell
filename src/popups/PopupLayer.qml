import QtQuick
import Quickshell
import "../"

// ============================================================
// PopupLayer — the only file that instantiates popup windows.
//
// shell.qml creates the anchor windows and passes them in.
// To add a new popup:
//   1. Create the .qml file in src/popups/
//   2. Add its anchor window as a property here (if new)
//   3. Instantiate it below under the right section
// ============================================================

Item {
    id: root

    // ── Anchor windows (set by shell.qml) ───────────────────
    required property var topBar       // TopBar PanelWindow
    required property var leftBorder   // left Border PanelWindow
    required property var rightBorder  // right Border PanelWindow
    required property var bottomBorder // bottom Border PanelWindow

    // ── Border-anchored popups ───────────────────────────────
    // These slide out from a screen edge. The notch is unaffected.

    // Left border → center
    ArchMenu {
        anchorWindow: root.leftBorder
    }

    // Right border → center  [placeholder — AudioMenu not built yet]
    // AudioMenu {
    //     anchorWindow: root.rightBorder
    // }

    // Bottom border → center  [placeholder — WallpaperMenu not built yet]
    // WallpaperMenu {
    //     anchorWindow: root.bottomBorder
    // }

    // ── TopBar-anchored popups ───────────────────────────────
    // These need the TopBar as anchor so they position correctly
    // relative to the notches.

    // Right notch area
    AudioPopup {
        anchorWindow: root.rightBorder
    }

    // Right notch  [placeholders — not built yet]
    // NotificationsPopup {
    //     anchorWindow: root.topBar
    //     notchWidth:   root.topBar.rWidth
    // }
    // NetworkPopup {
    //     anchorWindow: root.topBar
    //     notchWidth:   root.topBar.rWidth
    // }
    // SysTrayPopup {
    //     anchorWindow: root.topBar
    //     notchWidth:   root.topBar.rWidth
    // }

    // Center notch  [placeholder — Dashboard not built yet]
    // Dashboard {
    //     anchorWindow: root.topBar
    //     notchWidth:   root.topBar.cWidth
    // }
}
