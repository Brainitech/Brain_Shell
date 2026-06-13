import QtQuick
import Quickshell
import "../"

// ============================================================
// PopupLayer — popup window instantiation.
//
// Popups are created as direct children so they can react to
// Popups.*Open signals via Connections on startup.
// Each popup's PanelWindow manages its own visibility/lifetime
// internally (WlrLayer.Overlay + visible: windowVisible).
//
// To add a new popup:
//   1. Create the .qml file in src/popups/
//   2. Add it below
// ============================================================

Item {
    id: popupLayer

    required property var topBar
    required property var leftBorder
    required property var rightBorder
    required property var bottomBorder

    // ── Left border → center ──────────────────────────────────
    ArchMenu {
        anchorWindow: popupLayer.leftBorder
    }

    // ── Bottom border → slides up ────────────────────────────
    WallpaperPopup {}

    // ── Bottom-right corner → clipboard ──────────────────────
    ClipboardPopup {}

    // ── Right notch → audio ──────────────────────────────────
    AudioPopup {
        anchorWindow: popupLayer.rightBorder
    }

    // ── Quick control ─────────────────────────────────────────
    QuickControl {
        anchorWindow: popupLayer.topBar
    }

    // ── Center notch → dashboard ─────────────────────────────
    Dashboard {
        anchorWindow: popupLayer.topBar
    }

    // ── Right notch → notifications ───────────────────────────
    NotificationsPopup {
        anchorWindow: popupLayer.topBar
    }

    NotificationToast {
        anchorWindow: popupLayer.rightBorder
    }

    // ── Screen record options ─────────────────────────────────
    ScreenRecOptionsPopup {
        anchorWindow: popupLayer.topBar
    }

    // ── Network popup ─────────────────────────────────────────
    NetworkPopup {}
}
