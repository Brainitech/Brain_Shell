import QtQuick
import Quickshell
import "../shapes"
import "../services"
import "../"

// Left-edge popup anchored to the left Border PanelWindow.
// Each tab page declares its preferred (content) size; the window clamps
// that to [Theme.popupMinWidth .. Theme.popupMaxWidth] and
// [Theme.popupMinHeight .. Theme.popupMaxHeight] so the popup is always
// within reasonable bounds regardless of content changes.

PopupWindow {
    id: root

    required property var anchorWindow

    // Flare sizes that match PopupShape's ear geometry
    readonly property int fw: Theme.cornerRadius
    readonly property int fh: Theme.cornerRadius

    // ── Per-page preferred sizes ──────────────────────────────────────────────
    // These are the desired *content* dimensions.  Adjust them to match your
    // actual rendered content; the window will clamp them automatically.
    readonly property var pagePreferredHeights: ({
        "power":       220,
        "performance": 200,
        "stats":       250
    })

    readonly property var pagePreferredWidths: ({
        "power":       180,
        "performance": 250,
        "stats":       380
    })

    property string page: "power"

    // ── Clamped dimensions ────────────────────────────────────────────────────
    readonly property int contentWidth: Math.max(
        Theme.popupMinWidth,
        Math.min(Theme.popupMaxWidth,
                 pagePreferredWidths[page]  ?? Theme.popupMinWidth)
    )

    readonly property int contentHeight: Math.max(
        Theme.popupMinHeight,
        Math.min(Theme.popupMaxHeight,
                 pagePreferredHeights[page] ?? Theme.popupMinHeight)
    )

    // Add flare geometry to get final window size
    implicitWidth:  contentWidth  + fw
    implicitHeight: contentHeight + fh * 2

    // ── Window setup ─────────────────────────────────────────────────────────
    color:   "transparent"
    visible: Popups.archMenuOpen

    Behavior on implicitWidth  { NumberAnimation { duration: 200; easing.type: Easing.InOutQuart } }
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuart } }

    anchor.window:  anchorWindow
    anchor.gravity: Edges.Right
    anchor.rect: Qt.rect(
        0,
        anchorWindow.height / 2,
        anchorWindow.width,
        implicitHeight
    )

    // ── Background ───────────────────────────────────────────────────────────
    PopupShape {
        id: bg
        anchors.fill: parent
        attachedEdge: "left"
        color:        Theme.background
        radius:       Theme.cornerRadius
        flareWidth:   root.fw
        flareHeight:  root.fh
    }

    // ── Content container ─────────────────────────────────────────────────────
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

            // Vertical tab column
            Column {
                id: tabCol
                width:   40
                spacing: 30
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        { key: "power",       icon: "⏻" },
                        { key: "performance", icon: "⚡" },
                        { key: "stats",       icon: "📊" },
                    ]

                    delegate: Rectangle {
                        width:  tabCol.width
                        height: tabCol.width
                        radius: Theme.cornerRadius * 2

                        color: root.page === modelData.key
                               ? Theme.active
                               : (tabHov.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

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

            // Divider
            Rectangle {
                width:  1
                height: parent.height
                color:  Qt.rgba(1, 1, 1, 0.1)
            }

            // Page content
            Item {
                width:  parent.width - tabCol.width - 9
                height: parent.height
                clip:   true

                PowerMenu {
                    anchors.centerIn: parent
                    width:            parent.width
                    visible:          root.page === "power"
                }

                GfxControl {
                    anchors.centerIn: parent
                    width:            parent.width
                    height:           parent.height
                    visible:          root.page === "performance"
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
