import QtQuick
import Quickshell.Io
import "../"

// Power menu — a vertical list of power action buttons.
// Embed inside ArchMenu.qml.

Column {
    id: root
    spacing: 4
    width: parent.width

    readonly property var actions: [
        { label: "Shutdown",  icon: "⏻", cmd: ["systemctl", "poweroff"],             danger: true  },
        { label: "Reboot",    icon: "↺",  cmd: ["systemctl", "reboot"],               danger: true  },
        { label: "Suspend",   icon: "⏾", cmd: ["systemctl", "suspend"],              danger: false },
        { label: "Lock",      icon: "🔒", cmd: ["loginctl",  "lock-session"],         danger: false },
    ]

    Process {
        id: runner
        property var pendingCmd: []
        command: pendingCmd
        onRunningChanged: if (!running) pendingCmd = []
    }

    function run(cmd) {
        runner.pendingCmd = cmd
        runner.running    = true
    }

    Repeater {
        model: root.actions

        delegate: Rectangle {
            width:  root.width
            height: 44
            radius: Theme.cornerRadius
            color:  hov.hovered
                        ? (modelData.danger ? "#4d2020" : Theme.active)
                        : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text:            modelData.icon
                    font.pixelSize:  16
                    color:           modelData.danger && hov.hovered ? "#ff6b6b" : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text:            modelData.label
                    font.pixelSize:  13
                    color:           modelData.danger && hov.hovered ? "#ff6b6b" : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Popups.archMenuOpen = false
                    root.run(modelData.cmd)
                }
            }
        }
    }
}
