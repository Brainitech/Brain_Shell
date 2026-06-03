import Quickshell
import QtQuick
import "./src/windows"
import "./src/popups"
import "./src/"

ShellRoot {
    // Force-instantiate lazy singletons that need startup behavior
    property var _keybinds:   KeybindService
    property var _updater:    UpdateService

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property var modelData

                // ── Windows ──────────────────────────────────────
                TopBar    { id: topBar;        screen: modelData }

                Border    { id: leftBorder;    screen: modelData; edge: "left"   }
                Border    { id: rightBorder;   screen: modelData; edge: "right"  }
                Border    { id: bottomBorder;  screen: modelData; edge: "bottom" }

                // ── Overlays ─────────────────────────────────────
                // Dismisses all popups on click-outside or Escape
                PopupDismiss { screen: modelData }

                // GPU mode change confirmation modal
                ConfirmDialog { screen: modelData }

                // Shell update notification
                UpdatePopup { screen: modelData }

                // ── All popups ───────────────────────────────────
                // Add new popups in src/popups/PopupLayer.qml only
                PopupLayer {
                    topBar:       topBar
                    leftBorder:   leftBorder
                    rightBorder:  rightBorder
                    bottomBorder: bottomBorder
                }
            }
        }
    }
}
