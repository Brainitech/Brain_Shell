import QtQuick
import Quickshell
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../modules/Center/"
import '../services/'
import "../"

// Dashboard — PanelWindow (required for TextInput keyboard on Wayland).
// Mirrors WallpaperPopup pattern: top+left+right anchor, mask tracks sizer,
// WlrKeyboardFocus.OnDemand so TextInputs inside KanbanBoard receive keys.

PanelWindow {
    id: root

    // Kept for PopupLayer API compat — not used by PanelWindow positioning
    property var anchorWindow: null

    readonly property int fw: Theme.notchRadius
    readonly property int fh: Theme.notchRadius
    readonly property int animDuration: Theme.animDuration

    property string page: "home"

    // ── Surface config ────────────────────────────────────────────────────────
    color:   "transparent"
    visible: windowVisible

    anchors.top:   true
    anchors.left:  true
    anchors.right: true

    implicitHeight: Theme.notchHeight + Theme.dashboardHeight
    exclusionMode:  ExclusionMode.Ignore

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // ── Mask — input region limited to sizer only ─────────────────────────────
    mask: Region { item: maskProxy }
    Item {
        id:     maskProxy
        x:      (root.width - sizer.width) / 2
        y:      Theme.notchHeight - root.fh
        width:  sizer.width
        height: sizer.height
    }

    // ── Visibility gate ───────────────────────────────────────────────────────
    property bool windowVisible: false

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (Popups.dashboardOpen) {
                root.windowVisible = true
            } else {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: root.animDuration + 20
        onTriggered: {
            root.windowVisible = false
            tabBar.reset()
        }
    }

    // ── Sizer — grows from notch bottom, centered ─────────────────────────────
    Item {
        id: sizer
        anchors.top:              parent.top
        anchors.topMargin:        Theme.notchHeight - root.fh
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        width:  Popups.dashboardOpen
                    ? Theme.dashboardWidth + 2 * root.fw
                    : Theme.cNotchMinWidth + 2 * root.fw
        height: Popups.dashboardOpen ? Theme.dashboardHeight : root.fh / 2

        Behavior on width  { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "top"
            color:        Theme.background
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Item {
            id: content
            anchors {
                fill:         parent
                topMargin:    root.fh + 8
                leftMargin:   root.fw + 8
                rightMargin:  root.fw + 8
                bottomMargin: 8
            }

            opacity: Popups.dashboardOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.dashboardOpen
                        ? root.animDuration * 0.5
                        : root.animDuration * 0.15
                }
            }

            Column {
                anchors.fill: parent
                spacing: 0

                TabSwitcher {
                    id: tabBar
                    orientation: "horizontal"
                    width:       parent.width
                    currentPage: root.page
                    model: [
                        { key: "home",     icon: "󰋜",  label: "Home"   },
                        { key: "stats",    icon: "󰻠",  label: "System" },
                        { key: "kanban",   icon: "󰄬",  label: "Tasks"  },
                        { key: "launcher", icon: "󱓞",  label: "Apps"   },
                        { key: "config",   icon: "󰒓",  label: "Config" },
                    ]
                    onPageChanged: function(key) { root.page = key }
                }

                Item {
                    width:  parent.width
                    height: parent.height - tabBar.height

                    Item {
                        anchors.fill: parent
                        visible: root.page === "home"
                        DashHome { anchors.fill: parent }
                    }
                    Item {
                        anchors.fill: parent
                        visible: root.page === "stats"
                        DashStats { anchors.fill: parent }
                    }
                    Item {
                        anchors.fill: parent
                        visible: root.page === "kanban"
                        KanbanBoard { anchors.fill: parent }
                    }
                    Item {
                        anchors.fill: parent
                        visible: root.page === "launcher"
                        Text {
                            anchors.centerIn: parent
                            text:  "🚀 App Launcher"
                            color: Qt.rgba(1,1,1,0.3); font.pixelSize: 16
                        }
                    }
                    Item {
                        anchors.fill: parent
                        visible: root.page === "config"
                        Text {
                            anchors.centerIn: parent
                            text:  "⚙️ Config"
                            color: Qt.rgba(1,1,1,0.3); font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
}
