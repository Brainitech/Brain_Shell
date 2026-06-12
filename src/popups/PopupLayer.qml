import QtQuick
import Quickshell
import "../"

// ============================================================
// PopupLayer — the only file that instantiates popup windows.
// Ambxst-optimized: Loader-based popups — destroyed when closed,
// freeing GPU memory. Components only exist while visible.
//
// shell.qml creates the anchor windows and passes them in.
// To add a new popup:
//   1. Create the .qml file in src/popups/
//   2. Add its anchor window as a property here (if new)
//   3. Add a Loader + Timer entry below
// ============================================================

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
    id: popupLayer

    // ── Anchor windows (set by shell.qml) ───────────────────
    required property var topBar
    required property var leftBorder
    required property var rightBorder
    required property var bottomBorder

    // ── Border-anchored popups ───────────────────────────────

    // Left border → center
    ArchMenu {
        anchorWindow: popupLayer.leftBorder
    }

    // Bottom border → slides up
    WallpaperPopup {}

    // Bottom-right corner → clipboard history + emoji
    ClipboardPopup {}

    // ── TopBar-anchored popups ───────────────────────────────

    // Right notch — audio
    AudioPopup {
        anchorWindow: popupLayer.rightBorder
    }
    QuickControl {
        anchorWindow: popupLayer.topBar
    }

    // Center notch — dashboard (expands below the center notch)
    Dashboard {
        anchorWindow: popupLayer.topBar
    }

    // Right notch
    NotificationsPopup {
        anchorWindow: popupLayer.topBar
    }

    NotificationToast {
        anchorWindow: popupLayer.rightBorder
    }

    // Screen recorder strip options — appears below center notch on hover
    ScreenRecOptionsPopup {
        anchorWindow: popupLayer.topBar
    }

    NetworkPopup {}
}
