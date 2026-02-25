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

    // Left border → center
    ArchMenu {
        anchorWindow: root.leftBorder
    }

    // ── TopBar-anchored popups ───────────────────────────────

    // Right notch — audio
    AudioPopup {
        anchorWindow: root.rightBorder
    }

    // Center notch — dashboard (expands below the center notch)
    Dashboard {
        anchorWindow: root.topBar
    }

    // Right notch  [placeholders — not built yet]
    // NotificationsPopup {
    //     anchorWindow: root.topBar
    // }
    // NetworkPopup {
    //     anchorWindow: root.topBar
    // }
    // SysTrayPopup {
    //     anchorWindow: root.topBar
    // }

    // Bottom border → center  [placeholder — WallpaperMenu not built yet]
    // WallpaperMenu {
    //     anchorWindow: root.bottomBorder
    // }
}
