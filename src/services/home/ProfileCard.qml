import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../../"
import "../../components"

// Profile card — circular avatar, username, window manager, uptime.

StatCard {
    id: root
    padding: 0

    property real localScale: 1.0
    property string avatarPath: ""

    property string _user:   ""
    property string _wm:     ""
    property string _uptime: ""

    Process {
        command: ["bash", "-c", "echo $USER"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._user = line.trim()
            }
        }
    }

    Process {
        command: ["bash", "-c", "echo ${XDG_CURRENT_DESKTOP:-Hyprland}"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._wm = line.trim()
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["bash", "-c",
            "uptime -p | sed 's/up //' | sed 's/ hours\\?/h/' | " +
            "sed 's/ minutes\\?/m/' | sed 's/ days\\?/d/' | sed 's/, / /g'"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._uptime = line.trim()
            }
        }
    }

    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: { uptimeProc.running = false; uptimeProc.running = true }
    }

    Component.onCompleted: uptimeProc.running = true

    Row {
        anchors {
            left:           parent.left;  leftMargin:  Math.round(16 * localScale)
            right:          parent.right; rightMargin: Math.round(16 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(18 * localScale)

        // Circular avatar
        Item {
            width: Math.round(72 * localScale); height: Math.round(72 * localScale)
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(166/255,208/255,247/255,0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(80/255,130/255,190/255,0.14) }
                }
                border.color: Qt.rgba(166/255,208/255,247/255,0.22)
                border.width: 1
            }

            Rectangle {
                id: photoMask
                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            Image {
                anchors.fill: parent
                source:   root.avatarPath !== "" ? ("file://" + root.avatarPath) : ""
                fillMode: Image.PreserveAspectCrop
                smooth:   true
                visible:  root.avatarPath !== ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled:      true
                    maskSource:       photoMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin:  1.0
                }
            }

            Text {
                anchors.centerIn: parent
                text:           "󰀄"
                font.pixelSize: Math.round(28 * localScale)
                color:          Theme.active
                visible:        root.avatarPath === ""
            }
        }

        // Text stats
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(10 * localScale)

            Text {
                text:           root._user
                font.pixelSize: Math.round(17 * localScale); font.weight: Font.DemiBold
                color:          Theme.active
            }

            Row {
                spacing: Math.round(8 * localScale)
                Text {
                    text: "󰣇"; font.pixelSize: Math.round(12 * localScale); color: Theme.active
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root._wm; font.pixelSize: Math.round(12 * localScale)
                    color: Qt.rgba(205/255,214/255,244/255,0.55)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: Math.round(8 * localScale)
                Text {
                    text: "󰔚"; font.pixelSize: Math.round(12 * localScale); color: Theme.active
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root._uptime; font.pixelSize: Math.round(12 * localScale)
                    font.family: "JetBrains Mono"
                    color: Qt.rgba(205/255,214/255,244/255,0.55)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
