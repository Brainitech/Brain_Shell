import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"

// Full-screen dimmed modal — warns the user before switching GPU mode.
// Appears centered on screen. Switching GPU mode requires a logout.

PanelWindow {
    id: root

    color: "transparent"

    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    visible: Popups.gfxWarningOpen

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // --- Processes ---
    Process {
        id: switcher
        property string mode: ""
        command: ["supergfxctl", "-m", mode]
        onRunningChanged: if (!running) logout.running = true
    }

    Process {
        id: logout
        // Terminate Hyprland session — SDDM will show login screen
        command: ["hyprctl", "dispatch", "exit", "0"]
    }

    function confirm() {
        Popups.gfxWarningOpen = false
        switcher.mode         = Popups.pendingGfxMode
        switcher.running      = true
    }

    function cancel() {
        Popups.gfxWarningOpen = false
        Popups.pendingGfxMode = ""
    }

    // --- Dim overlay ---
    Rectangle {
        anchors.fill: parent
        color:        "#99000000"   // semi-transparent black

        // Dismiss on click outside dialog
        MouseArea {
            anchors.fill: parent
            onClicked:    root.cancel()
        }
    }

    // --- Dialog box ---
    Rectangle {
        anchors.centerIn: parent
        width:  360
        height: col.implicitHeight + 48
        radius: Theme.notchRadius
        color:  Theme.background

        // Swallow clicks so they don't hit the dim overlay behind
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors {
                top:              parent.top
                left:             parent.left
                right:            parent.right
                topMargin:        24
                leftMargin:       24
                rightMargin:      24
            }
            spacing: 16

            // Icon
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "⚠️"
                font.pixelSize: 32
            }

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "Switching Graphics Mode"
                color:          Theme.text
                font.pixelSize: 15
                font.bold:      true
            }

            // Body
            Text {
                width:     parent.width
                text:      "Switching to <b>"
                           + Popups.pendingGfxMode
                           + "</b> mode requires saving your work and logging out. "
                           + "Your session will end immediately after the change is applied."
                color:     Qt.rgba(1, 1, 1, 0.65)
                font.pixelSize: 12
                wrapMode:  Text.WordWrap
                textFormat: Text.RichText
                lineHeight: 1.4
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

                // Confirm
                Rectangle {
                    width:  130
                    height: 38
                    radius: Theme.cornerRadius
                    color:  confirmHov.hovered ? "#cc3a3a" : "#993030"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text:           "Switch & Log Out"
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
