import QtQuick
import "../"
import "../../"
import "../../components"

Item {
    id: root

    property real localScale: 1.0
    property string _page: "general"

    readonly property var _tabs: [
        { key: "general",    icon: "󰒓", label: "General"            },
        { key: "visuals",    icon: "󰏘", label: "Visuals & Behavior" },
        { key: "keybinds",   icon: "󰌌", label: "Keybinds"          },
        { key: "data",       icon: "󰋊", label: "Data & Storage"    },
        { key: "misc",       icon: "󰒓", label: "Misc"               },
    ]

    Row {
        anchors {
            fill:    parent
            margins: Math.round(8 * localScale)
        }
        spacing: Math.round(12 * localScale)

        // ── Left: tab column (30%) ────────────────────────────────────────────
        Rectangle {
            width:  Math.floor((parent.width - parent.spacing) * 0.30)
            height: parent.height
            radius: Math.round(Theme.cornerRadius * localScale)
            color:  Qt.rgba(1, 1, 1, 0.04)
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1

            TabSwitcher {
                localScale:  root.localScale
                orientation: "vertical"
                anchors {
                    top:              parent.top
                    bottom:           parent.bottom
                    left:             parent.left
                    right:            parent.right
                    topMargin:        Math.round(8 * localScale)
                    bottomMargin:     Math.round(8 * localScale)
                    leftMargin:       Math.round(6 * localScale)
                    rightMargin:      Math.round(6 * localScale)
                }
                currentPage: root._page
                model:       root._tabs
                onPageChanged: function(key) { root._page = key }
            }
        }

        // ── Right: content area (70%) ─────────────────────────────────────────
        Item {
            width:  parent.width - Math.floor((parent.width - parent.spacing) * 0.30) - parent.spacing
            height: parent.height

            Item {
                anchors.fill: parent
                visible: root._page === "general"
                GeneralPage { anchors.fill: parent; localScale: root.localScale }
            }
            Item {
                anchors.fill: parent
                visible: root._page === "visuals"
                VisualsBehaviorPage { anchors.fill: parent; localScale: root.localScale }
            }
            Item {
                anchors.fill: parent
                visible: root._page === "keybinds"
                KeybindsPage { 
                    anchors.fill: parent 
                    // localScale: root.localScale // If KeybindsPage is updated later
                }
            }
            Item {
                anchors.fill: parent
                visible: root._page === "data"
                DataPage { anchors.fill: parent; localScale: root.localScale }
            }
            Item {
                anchors.fill: parent
                visible: root._page === "misc"
                MiscPage { anchors.fill: parent; localScale: root.localScale }
            }
        }
    }
}