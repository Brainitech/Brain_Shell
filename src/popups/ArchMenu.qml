import QtQuick
import Quickshell
import "../shapes"
import "../services"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow

    readonly property int fw:            Theme.cornerRadius
    readonly property int fh:            Theme.cornerRadius
    readonly property int contentWidth:  Theme.lNotchWidth / 1.5
    readonly property int contentHeight: 200

    property string page: "power"

    color:          "transparent"
    visible:        Popups.archMenuOpen

    implicitWidth:  contentWidth  + fw
    implicitHeight: contentHeight + fh * 2

    // Vertically centered on the left border
    anchor.window:  anchorWindow
    anchor.gravity: Edges.Right
    anchor.rect: Qt.rect(
        0,
        (anchorWindow.height / 2),
        anchorWindow.width,
        implicitHeight
    )

    // --- Background ---
    PopupShape {
        id: bg
        anchors.fill: parent
        attachedEdge: "left"
        color:        Theme.background
        radius:       Theme.cornerRadius
        flareWidth:   root.fw
        flareHeight:  root.fh
    }

    // --- Content container ---
    // Inset to stay inside the PopupShape body region
    Item {
        anchors {
            fill:         parent
            leftMargin:   root.fw + 6
            rightMargin:  8
            topMargin:    root.fh + 6
            bottomMargin: root.fh + 6
        }

        Row {
            anchors.fill: parent
            spacing: 8

            // --- Left: vertical tab column ---
            Column {
                id: tabCol
                width:   36
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        { key: "power", icon: "⏻" },
                        { key: "stats", icon: "📊" },
                    ]

                    delegate: Rectangle {
                        width:  tabCol.width
                        height: tabCol.width   // square tab
                        radius: Theme.cornerRadius

                        color: root.page === modelData.key
                                   ? Theme.active
                                   : (tabHov.hovered ? Qt.rgba(1,1,1,0.08) : "transparent")

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text:            modelData.icon
                            font.pixelSize:  16
                            color: root.page === modelData.key
                                       ? Theme.background
                                       : Theme.text
                        }

                        HoverHandler { id: tabHov; cursorShape: Qt.PointingHandCursor }

                        MouseArea {
                            anchors.fill: parent
                            onClicked:    root.page = modelData.key
                        }
                    }
                }
            }

            // --- Vertical divider ---
            Rectangle {
                width:  1
                height: parent.height
                color:  Qt.rgba(1, 1, 1, 0.1)
            }

            // --- Right: page content ---
            Item {
                width:  parent.width - tabCol.width - 9   // 9 = spacing + divider
                height: parent.height

                PowerMenu {
                    anchors.centerIn: parent
                    width:            parent.width
                    visible:          root.page === "power"
                }

                SystemStats {
                    anchors.centerIn: parent
                    width:            parent.width
                    height:           parent.height
                    visible:          root.page === "stats"
                }
            }
        }
    }
}
