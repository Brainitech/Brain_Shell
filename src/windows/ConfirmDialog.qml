import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"

// Unified confirmation modal — replaces GfxWarning.qml.
// Driven entirely by Popups.confirm* props.
// Call Popups.showConfirm() to open, Popups.cancelConfirm() to close.
//
// Supported confirmAction values:
//   "shutdown"   → systemctl poweroff
//   "reboot"     → systemctl reboot
//   "suspend"    → systemctl suspend
//   "lock"       → loginctl lock-session
//   "gfx-switch" → supergfxctl -m <confirmGfxMode>, then hyprctl exit

PanelWindow {
    id: root

    color: "transparent"

    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    visible: Popups.confirmOpen

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: proc
        property var pendingCmd: []
        command: pendingCmd
        onRunningChanged: if (!running && logout.command.length > 0) logout.running = true
    }

    Process {
        id: logout
        command: []   // only populated for gfx-switch
    }

    // ── Action dispatch ───────────────────────────────────────────────────────
    function confirm() {
        Popups.confirmOpen = false
        Popups.closeAll()

        switch (Popups.confirmAction) {
            case "shutdown":
                proc.pendingCmd = ["systemctl", "poweroff"]
                proc.running = true
                break
            case "reboot":
                proc.pendingCmd = ["systemctl", "reboot"]
                proc.running = true
                break
            case "suspend":
                proc.pendingCmd = ["systemctl", "suspend"]
                proc.running = true
                break
            case "lock":
                proc.pendingCmd = ["loginctl", "lock-session"]
                proc.running = true
                break
            case "gfx-switch":
                logout.command = ["hyprctl", "dispatch", "exit", "0"]
                proc.pendingCmd = ["supergfxctl", "-m", Popups.confirmGfxMode]
                proc.running = true
                break
        }

        Popups.cancelConfirm()
    }

    function cancel() {
        Popups.cancelConfirm()
    }

    // ── Dim overlay ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#99000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    // ── Dialog ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  360
        height: col.implicitHeight + 48
        radius: Theme.notchRadius
        color:  Theme.background

        MouseArea { anchors.fill: parent }  // swallow clicks

        Column {
            id: col
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   24
                leftMargin:  24
                rightMargin: 24
            }
            spacing: 16

            // Icon — changes based on action type
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    switch (Popups.confirmAction) {
                        case "shutdown":   return "⏻"
                        case "reboot":     return "↺"
                        case "gfx-switch": return "⚠️"
                        default:           return "⚠️"
                    }
                }
                font.pixelSize: 32
            }

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           Popups.confirmTitle
                color:          Theme.text
                font.pixelSize: 15
                font.bold:      true
            }

            // Message
            Text {
                width:          parent.width
                text:           Popups.confirmMessage
                color:          Qt.rgba(1, 1, 1, 0.65)
                font.pixelSize: 12
                wrapMode:       Text.WordWrap
                textFormat:     Text.RichText
                lineHeight:     1.4
            }

            // Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                // Cancel
                Rectangle {
                    width:  130
                    height: 38
                    radius: Theme.cornerRadius
                    color:  cancelHov.hovered
                                ? Qt.rgba(1, 1, 1, 0.1)
                                : Qt.rgba(1, 1, 1, 0.05)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text:           "Cancel"
                        color:          Theme.text
                        font.pixelSize: 13
                    }

                    HoverHandler { id: cancelHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.cancel() }
                }

                // Confirm — always red for destructive actions
                Rectangle {
                    width:  130
                    height: 38
                    radius: Theme.cornerRadius
                    color:  confirmHov.hovered ? "#cc3a3a" : "#993030"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text:           Popups.confirmLabel
                        color:          "white"
                        font.pixelSize: 13
                        font.bold:      true
                    }

                    HoverHandler { id: confirmHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: root.confirm() }
                }
            }
        }
    }

    // Escape to cancel
    Item {
        anchors.fill: parent
        Keys.onEscapePressed: root.cancel()
    }
}
