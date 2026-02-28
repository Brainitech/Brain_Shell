import QtQuick
import Quickshell
import "../shapes"
import "../services"
import "../components"
import "../"

PopupWindow {
    id: root

    required property var anchorWindow

    readonly property int fw: Theme.cornerRadius
    readonly property int fh: Theme.cornerRadius

    // pageWidths drives the sizer width per page
    // pageHeights drives the sizer height per page
    readonly property var pageHeights: ({
        "power":       270,
        "performance": 190,
        "stats":       250
    })
    readonly property var pageWidths: ({
        "power":       220,
        "performance": 260,
        "stats":       390
    })

    readonly property int contentWidth:  pageWidths[page]  ?? 220
    readonly property int contentHeight: pageHeights[page] ?? 220

    property string page: "power"

    color:   "transparent"
    visible: slide.windowVisible

    implicitWidth:  (pageWidths["stats"]  ?? 220) + fw
    implicitHeight: (pageHeights["stats"] ?? 220) + fh * 2

    anchor.window:  anchorWindow
    anchor.gravity: Edges.Right
    anchor.rect: Qt.rect(
        0,
        anchorWindow.height / 2,
        anchorWindow.width,
        implicitHeight
    )

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge: "left"
        hoverEnabled: false
        triggerHovered:  Popups.archMenuTriggerHovered
        open: Popups.archMenuOpen

        Item {
            id: sizer
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            width:  root.contentWidth  + root.fw
            height: root.contentHeight + root.fh * 2

            Behavior on width  { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }
            Behavior on height { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

            PopupShape {
                id: bg
                anchors.fill: parent
                attachedEdge: "left"
                color:        Theme.background
                radius:       Theme.cornerRadius
                flareWidth:   root.fw
                flareHeight:  root.fh
            }

            Item {
                anchors {
                    fill:         parent
                    leftMargin:   root.fw - 4
                    rightMargin:  8
                    topMargin:    root.fh + 6
                    bottomMargin: root.fh + 6
                }

                Row {
                    anchors.fill: parent
                    spacing: 8
                    
                    // ── Tab switcher — left side ───────────────────────────────
                    TabSwitcher {
                        id: switcher
                        orientation: "vertical"
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        model: [
                            { key: "power",       icon: "⏻" },
                            { key: "performance", icon: "󰢮" },
                            { key: "stats",       icon: "≡" },
                        ]
                        currentPage: root.page
                        onPageChanged: function(key) { root.page = key }
                    }

                    Rectangle {
                        width: 1; height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.1)
                    }

                    // ── Page content ──────────────────────────────────────────
                    Item {
                        width:  parent.width - switcher.implicitWidth - 1 - parent.spacing * 2
                        height: parent.height
                        clip:   true

                        // Power — PopupPage wraps a fixed-height Column, works fine
                        PopupPage {
                            anchors.fill: parent
                            visible: root.page === "power"

                            PowerMenu {
                                // PowerMenu is a Column — just give it width,
                                // it sizes itself by its children
                                width: parent.width
                            }
                        }

                        // Performance — EnvyControl is a Column; give it width
                        // and let it size itself. Do NOT pass height.
                        PopupPage {
                            anchors.fill: parent
                            visible: root.page === "performance"

                            EnvyControl {
                                width: parent.width
                                // height intentionally omitted — Column auto-sizes
                            }
                        }

                        // Stats — SystemStats root Item needs a height.
                        // We give it the sizer content height minus padding.
                        PopupPage {
                            anchors.fill: parent
                            visible: root.page === "stats"

                            SystemStats {
                                width:  parent.width
                                // Item needs explicit height since it uses
                                // internal anchors rather than implicitHeight.
                                // Use the page content height minus PopupPage padding.
                                height: root.contentHeight - root.fh * 2 - 12 - 16
                            }
                        }
                    }
                }
            }
        }
    }
}
