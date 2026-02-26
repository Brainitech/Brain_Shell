import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../../"

Item {
    width: Theme.cNotchMinWidth
    height: 30

    // ── Carousel — fades out while dashboard is open ──────────────────────────
    Item {
        anchors.fill: parent

        opacity: Popups.dashboardOpen ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ListView {
            id: statusList
            anchors.fill: parent
            orientation: ListView.Vertical
            spacing: 15
            clip: true
            snapMode: ListView.SnapOneItem

            model: ObjectModel {
                Text {
                    width: Theme.cNotchMinWidth; height: 30
                    verticalAlignment:   Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text:  "Work In Progress"
                    color: "#ffffff"
                }

                Text {
                    width: Theme.cNotchMinWidth; height: 30
                    verticalAlignment:   Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text:  Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
                    color: Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    width: Theme.cNotchMinWidth; height: 30
                    verticalAlignment:   Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text:  "ArchLinux"
                    color: "#FFFFFF"
                }
            }
        }
    }

    // ── Dashboard-open indicator — fades in when dashboard is open ────────────
    Text {
        anchors.centerIn: parent
        text:    "▾"
        color:   Theme.active
        font.pixelSize: 14
        opacity: Popups.dashboardOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ── Click anywhere in the notch to toggle the dashboard ──────────────────
    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var next = !Popups.dashboardOpen
            Popups.closeAll()
            Popups.dashboardOpen = next
        }
    }
}
