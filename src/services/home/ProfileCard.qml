import QtQuick
import Quickshell.Io
import "../../"
import "../../components"

// Profile card — username, avatar, live date.
// Self-contained: owns its own date timer.

StatCard {
    id: root
    padding: 0

    // ── State ─────────────────────────────────────────────────────────────────
    property string _dateStr: ""
    property string _user:    ""

    Process {
        command: ["bash", "-c", "echo $USER"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._user = line.trim()
            }
        }
    }

    readonly property var _monthNames: [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    function _updateDate() {
        var d    = new Date()
        var dows = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
        var dd   = d.getDate(); var ds = dd < 10 ? "0"+dd : ""+dd
        _dateStr = dows[d.getDay()] + "  " + ds + " " +
                   _monthNames[d.getMonth()].substring(0,3).toUpperCase() + " " +
                   d.getFullYear()
    }

    Component.onCompleted: _updateDate()

    // Updates once per minute — date never changes faster
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root._updateDate() }

    // ── UI ────────────────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 10

            // Avatar circle
            Rectangle {
                width: 64; height: 64; radius: 32
                anchors.horizontalCenter: parent.horizontalCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(166/255,208/255,247/255,0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(80/255,130/255,190/255,0.14) }
                }
                border.color: Qt.rgba(166/255,208/255,247/255,0.22)
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "󰀄"; font.pixelSize: 28; color: Theme.active
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._user; font.pixelSize: 14; font.weight: Font.DemiBold
                    color: Qt.rgba(235/255,240/255,255/255,0.9)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._dateStr; font.pixelSize: 9; font.family: "JetBrains Mono"
                    color: Qt.rgba(205/255,214/255,244/255,0.35)
                }
            }
        }
    }
}
