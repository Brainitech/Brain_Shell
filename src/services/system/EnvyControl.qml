import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "../"

// Graphics & power status panel.

Column {
    id: root
    property real localScale: 1.0
    spacing: Math.round(12 * localScale)
    width: parent.width

    readonly property var  bat:      UPower.displayDevice
    readonly property bool charging: bat.ready
                                     ? (bat.state === UPowerDeviceState.Charging ||
                                        bat.state === UPowerDeviceState.PendingCharge ||
                                        bat.state === UPowerDeviceState.FullyCharged)
                                     : false

    property string powerProfile: charging ? "Performance" : "Powersave"
    property string gfxMode:      "..."
    property bool   dgpuEnabled:  false

    Process {
        id: gfxReader
        command: ["envycontrol", "-q"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var mode = text.trim()
                root.gfxMode     = mode
                root.dgpuEnabled = (mode === "hybrid")
            }
        }
    }

    onVisibleChanged: if (visible) gfxReader.running = true

    // ── Power profile row (read-only) ─────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 4

        Text {
            text:                "Power Profile"
            color:               Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize:      Math.round(10 * localScale)
            font.capitalization: Font.AllUppercase
            leftPadding:         Math.round(2 * localScale)
        }

        Rectangle {
            width:  parent.width
            height: Math.round(40 * localScale)
            radius: Math.round(Theme.cornerRadius * localScale)
            color:  Qt.rgba(1, 1, 1, 0.05)

            Row {
                anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                spacing: Math.round(8 * localScale)

                Text { text: "⚙️"; font.pixelSize: Math.round(14 * localScale); anchors.verticalCenter: parent.verticalCenter }

                Text {
                    text:           root.powerProfile.charAt(0).toUpperCase()
                                    + root.powerProfile.slice(1)
                    color:          Theme.text
                    font.pixelSize: Math.round(13 * localScale)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors { right: parent.right; rightMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
                text:    "🔒"
                font.pixelSize: Math.round(12 * localScale)
                opacity: 0.4
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

    // ── dGPU toggle row ───────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: Math.round(4 * localScale)

        Text {
            text:                "Graphics"
            color:               Qt.rgba(1, 1, 1, 0.4)
            font.pixelSize:      Math.round(10 * localScale)
            font.capitalization: Font.AllUppercase
            leftPadding:         Math.round(2 * localScale)
        }

        Rectangle {
            width:  parent.width
            height: Math.round(48 * localScale)
            radius: Math.round(Theme.cornerRadius * localScale)
            color:  Qt.rgba(1, 1, 1, 0.05)

            Row {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 8

                Text {
                    text:           root.dgpuEnabled ? "🖥️" : "💻"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text:           root.dgpuEnabled ? "Hybrid" : "Integrated"
                        color:          Theme.text
                        font.pixelSize: 13
                        font.bold:      true
                    }

                    Text {
                        text:           root.dgpuEnabled ? "dGPU active" : "dGPU inactive"
                        color:          Qt.rgba(1, 1, 1, 0.45)
                        font.pixelSize: 10
                    }
                }
            }

            // Toggle switch
            Rectangle {
                id: toggle
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                width:  44
                height: 24
                radius: 12
                color:  root.dgpuEnabled ? Theme.active : Qt.rgba(1, 1, 1, 0.15)
                Behavior on color { ColorAnimation { duration: Anim.mediumFast} }

                Rectangle {
                    width:  18; height: 18; radius: 9
                    color:  "white"
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.dgpuEnabled ? parent.width - width - 3 : 3
                    Behavior on x { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic} }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Display label is capitalised; CLI arg must be lowercase
                        var displayMode = root.dgpuEnabled ? "Integrated" : "Hybrid"
                        var cliMode     = displayMode.toLowerCase()
                        Popups.showConfirm(
                            "Switch Graphics Mode",
                            "Switching to <b>" + displayMode + "</b> mode requires saving your "
                            + "work and rebooting. Your system will restart immediately after "
                            + "the change is applied.",
                            "Switch & Reboot",
                            "gfx-switch",
                            cliMode
                        )
                    }
                }
            }
        }
    }
}
