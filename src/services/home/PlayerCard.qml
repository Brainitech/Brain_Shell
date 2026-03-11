import QtQuick
import "../../"
import "../../components"

// Media player card — MPRIS stub.
// Square album art on the left, track info + controls on the right.

StatCard {
    id: root
    padding: 0

    Row {
        anchors.fill: parent; spacing: 0

        // ── Album art ─────────────────────────────────────────────────────────
        Rectangle {
            id: art
            width: parent.height; height: parent.height
            radius: Theme.cornerRadius; clip: true
            color: "#0d1e2b"

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(166/255,208/255,247/255,0.06) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Static disc rings
            Item {
                anchors.centerIn: parent; width: 70; height: 70
                Rectangle {
                    anchors.centerIn: parent; width: parent.width; height: parent.width; radius: parent.width/2
                    color: "transparent"
                    border.color: Qt.rgba(166/255,208/255,247/255,0.18); border.width: 1
                }
                Rectangle {
                    anchors.centerIn: parent; width: 50; height: 50; radius: 25
                    color: "transparent"
                    border.color: Qt.rgba(166/255,208/255,247/255,0.09); border.width: 1
                }
                Rectangle {
                    anchors.centerIn: parent; width: 16; height: 16; radius: 8
                    color: "#0a1420"
                    border.color: Qt.rgba(166/255,208/255,247/255,0.22); border.width: 1
                }
            }
        }

        // ── Track info + controls ─────────────────────────────────────────────
        Item {
            width: parent.width - art.width; height: parent.height

            // Top: badge, title, artist, progress
            Column {
                anchors {
                    top: parent.top; topMargin: 14
                    left: parent.left; leftMargin: 14
                    right: parent.right; rightMargin: 14
                }
                spacing: 5

                // Source badge
                Rectangle {
                    height: 18; width: badge.implicitWidth + 14; radius: 9
                    color: Qt.rgba(166/255,208/255,247/255,0.07)
                    border.color: Qt.rgba(166/255,208/255,247/255,0.14); border.width: 1
                    Row {
                        id: badge; anchors.centerIn: parent; spacing: 5
                        Rectangle {
                            width: 5; height: 5; radius: 2.5; color: Theme.active
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700 }
                                NumberAnimation { to: 1.0; duration: 700 }
                            }
                        }
                        Text {
                            text: "No media"; font.pixelSize: 9; font.weight: Font.Bold
                            font.letterSpacing: 0.8; color: Theme.active
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Text {
                    width: parent.width; text: "Nothing Playing"
                    font.pixelSize: 15; font.weight: Font.Bold
                    color: Qt.rgba(235/255,240/255,255/255,0.9); elide: Text.ElideRight
                }
                Text {
                    width: parent.width; text: "Open a media player"
                    font.pixelSize: 11; color: Qt.rgba(205/255,214/255,244/255,0.35)
                    elide: Text.ElideRight
                }

                // Progress + timestamps
                Item {
                    width: parent.width; height: 22

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 4; radius: 2
                        color: Qt.rgba(1,1,1,0.08)
                        Rectangle { width: 0; height: parent.height; radius: 2; color: Theme.active }
                    }
                    Text {
                        anchors { left: parent.left; bottom: parent.bottom }
                        text: "0:00"; font.pixelSize: 9; font.family: "JetBrains Mono"
                        color: Qt.rgba(1,1,1,0.2)
                    }
                    Text {
                        anchors { right: parent.right; bottom: parent.bottom }
                        text: "0:00"; font.pixelSize: 9; font.family: "JetBrains Mono"
                        color: Qt.rgba(1,1,1,0.2)
                    }
                }
            }

            // Bottom: shuffle · prev · play · next · repeat
            Row {
                anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
                spacing: 4

                Repeater {
                    model: [
                        { icon: "⇄", key: "shuffle", play: false },
                        { icon: "⏮", key: "prev",    play: false },
                        { icon: "⏵", key: "play",    play: true  },
                        { icon: "⏭", key: "next",    play: false },
                        { icon: "↺", key: "repeat",  play: false }
                    ]
                    delegate: Rectangle {
                        required property var  modelData
                        required property int  index
                        width: modelData.play ? 40 : 30; height: modelData.play ? 40 : 30
                        radius: modelData.play ? 10 : 8
                        color: modelData.play ? Qt.rgba(166/255,208/255,247/255,0.12)
                               : bH.hovered ? Qt.rgba(1,1,1,0.07) : "transparent"
                        border.color: modelData.play ? Qt.rgba(166/255,208/255,247/255,0.22) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent; text: modelData.icon
                            font.pixelSize: modelData.play ? 16 : 12
                            color: modelData.play ? Theme.active : Qt.rgba(1,1,1,0.35)
                        }
                        HoverHandler { id: bH; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}
