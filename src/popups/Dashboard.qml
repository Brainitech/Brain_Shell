import QtQuick
import Quickshell
import "../shapes"
import "../components"  
import "../modules/Center/"
import '../services/'
import "../"

// Dashboard — drops below the center notch when Popups.dashboardOpen is true.
//
// Animation: sizer starts at notch width + 0 height, then both width and
// height grow simultaneously to full dashboard size. This creates a "growing
// from the notch" effect — narrow at first, widening as the panel descends.
//
// The PopupWindow is fixed size — no compositor resize ever occurs.

PopupWindow {
    id: root

    required property var anchorWindow

    // Flare connects the popup seamlessly to the underside of the notch bar
    readonly property int fw: Theme.notchRadius
    readonly property int fh: Theme.notchRadius

    readonly property int animDuration: Theme.animDuration
    
    property string page: "home"

    color:   "transparent"
    visible: windowVisible

    // ── Window visibility gate ────────────────────────────────────────────────
    // Keep the window alive until the close animation finishes, then hide it.
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

    // ── Positioning ───────────────────────────────────────────────────────────
    // Sits at the bottom edge of the center notch, centered horizontally.
    // The sizer fans outward from this anchor point.
    anchor.window:  anchorWindow
    anchor.gravity: Edges.Bottom
    anchor.rect: Qt.rect(
        anchorWindow.width / 2,
        0,
        Theme.dashboardWidth,
        Theme.notchHeight
    )

    // Fixed at max dimensions — the sizer clips internally
    implicitWidth:  Theme.dashboardWidth
    implicitHeight: Theme.dashboardHeight

    // ── Sizer ─────────────────────────────────────────────────────────────────
    // Anchored top-center so growth radiates outward and downward from the notch.
    // Width starts at cNotchMinWidth (matches closed notch visually),
    // height starts at 0.
    Item {
        id: sizer
        anchors.top:              parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        width:  Popups.dashboardOpen ? Theme.dashboardWidth+2*root.fw  : Theme.cNotchMinWidth+2*root.fw
        height: Popups.dashboardOpen ? Theme.dashboardHeight : Theme.notchHeight /2

        Behavior on width {
            NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic }
        }

        // ── Background ────────────────────────────────────────────────────────
        PopupShape {
            id: bg
            anchors.fill: parent
            attachedEdge: "top"
            color:        Theme.background
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        // ── Content ───────────────────────────────────────────────────────────
        // Inset clear of the flare region. Fades in after the panel has
        // mostly expanded, fades out immediately on close.
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

            // ── Placeholder ───────────────────────────────────────────────────
            Column {
                anchors.fill: parent
                spacing: 0

                // ── Tab bar ───────────────────────────────────────────────────
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

                // ── Page area ─────────────────────────────────────────────────
                Item {
                    width:  parent.width
                    height: parent.height - tabBar.height

                    // Home
                    // Item {
                    //     anchors.fill: parent
                    //     visible:      root.page === "home"
                    //     Text {
                    //         anchors.centerIn: parent
                    //         text:  "🏠 Home"
                    //         color: Qt.rgba(1,1,1,0.3)
                    //         font.pixelSize: 16
                    //     }
                    // }
                                        Item {
        anchors.fill: parent
       visible:      root.page === "home"
         DashHome { anchors.fill: parent }
    }

                    // Stats
                    Item {
                        anchors.fill: parent
                        visible:      root.page === "stats"
                        DashStats {anchors.fill: parent}
                    }

                    // Kanban
                    Item {
                        anchors.fill: parent
                        visible:      root.page === "kanban"
                        Text {
                            anchors.centerIn: parent
                            text:  "📋 Tasks"
                            color: Qt.rgba(1,1,1,0.3)
                            font.pixelSize: 16
                        }
                    }

                    // App Launcher
                    Item {
                        anchors.fill: parent
                        visible:      root.page === "launcher"
                        Text {
                            anchors.centerIn: parent
                            text:  "🚀 App Launcher"
                            color: Qt.rgba(1,1,1,0.3)
                            font.pixelSize: 16
                        }
                    }

                    // Config
                    Item {
                        anchors.fill: parent
                        visible:      root.page === "config"
                        Text {
                            anchors.centerIn: parent
                            text:  "⚙️ Config"
                            color: Qt.rgba(1,1,1,0.3)
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
}
