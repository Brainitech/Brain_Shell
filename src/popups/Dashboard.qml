import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../modules/Center/"
import '../services/'
import "../"
import "../theme"

// Dashboard — PanelWindow required for TextInput keyboard focus on Wayland.
// Uses WlrKeyboardFocus.Exclusive so TextInputs inside pages receive key events.
//
// Positioning mirrors the original PopupWindow behaviour: the sizer's top sits
// exactly at the notch-bar bottom (topMargin: Theme.notchHeight), so there is
// no vertical offset compared to the PopupWindow version.

PanelWindow {
    id: root

    // Kept so existing instantiation sites that pass anchorWindow: … still compile.
    required property var anchorWindow

    readonly property int fw: Theme.notchRadius
    readonly property int fh: Theme.notchRadius
    readonly property int animDuration: Anim.standardNormal

    property string page: Popups.dashboardPage

    // ── Per-page content widths ───────────────────────────────────────────────
    readonly property var _pageWidths: ({
        "home":     900,
        "stats":    900,
        "kanban":   900,
        "launcher": 560,
        "config":   900
    })

    function _applyPageWidth(p) {
        var w = _pageWidths[p]
        Popups.dashboardPageWidth = (w !== undefined) ? w : 900
    }

    onPageChanged: _applyPageWidth(page)

    color:   "transparent"
    visible: windowVisible

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    anchors.bottom: true

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer:         WlrLayer.Overlay
    // Exclusive focus only when fully open and visible.
    WlrLayershell.keyboardFocus: (windowVisible && Popups.dashboardOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool windowVisible: false

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (Popups.dashboardOpen) {
                closeTimer.stop()
                root.windowVisible = true
                root._applyPageWidth(root.page)
            } else {
                closeTimer.restart()
            }
        }

        function onDashboardPageChanged() {
            root.page = Popups.dashboardPage
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

    // ── Backdrop — closes popup when clicking outside the sizer ──────────────
    MouseArea {
        anchors.fill: parent
        onClicked:    Popups.dashboardOpen = false
    }

    // ── Sizer ─────────────────────────────────────────────────────────────────
    // topMargin: Theme.notchHeight places the sizer top exactly at the notch
    // bottom — identical to where PopupWindow put it. No fh subtraction, which
    // was the source of the vertical offset in the text-working variant.
    Item {
        id: sizer
        anchors.top:              parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        width:  Popups.dashboardOpen ? Popups.dashboardPageWidth + 2 * root.fw : Theme.cNotchMinWidth + 2 * root.fw
        height: Popups.dashboardOpen ? Theme.dashboardHeight : Theme.notchHeight / 2

        Behavior on width  { NumberAnimation { duration: root.animDuration; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }
        Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Anim.easing("standard").type; easing.bezierCurve: Anim.easing("standard").bezierCurve } }
        
        MouseArea {
            anchors.fill: parent
            onClicked:    {}
        }

        // ── Background ────────────────────────────────────────────────────────
        PopupShape {
            anchors.fill: parent
            attachedEdge: "top"
            color:        Theme.background
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        // ── Content ───────────────────────────────────────────────────────────
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
                        ? Math.round(root.animDuration * 0.5)
                        : Math.round(root.animDuration * 0.15)
                    easing.type: Anim.easing("standard").type
                    easing.bezierCurve: Anim.easing("standard").bezierCurve
                }
            }

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
                        { key: "home",     icon: "󰋜", label: "Home"   },
                        { key: "stats",    icon: "󰻠", label: "System" },
                        { key: "kanban",   icon: "󰄬", label: "Tasks"  },
                        { key: "launcher", icon: "󱓞", label: "Apps"   },
                        { key: "config",   icon: "󰒓", label: "Config" },
                    ]
                    onPageChanged: function(key) { Popups.dashboardPage = key }
                }

                // ── Page area — simple visibility toggle (original pattern) ─────
                // Pages are created once and toggled via visible binding.
                // This is lighter than Loader/StackView and avoids re-creation lag.
                Item {
                    id: pageArea
                    focus: true
                    
                    width:  parent.width
                    height: parent.height - tabBar.height

                    // ── Home ────────────────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.page === "home"
                        DashHome { anchors.fill: parent }
                    }

                    // ── System Stats ─────────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.page === "stats"
                        DashStats { anchors.fill: parent }
                    }

                    // ── Kanban Tasks ─────────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.page === "kanban"
                        KanbanBoard { anchors.fill: parent }
                    }

                    // ── App Launcher ─────────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.page === "launcher"
                        AppLauncher { anchors.fill: parent }
                    }

                    // ── Config ───────────────────────────────────────────────
                    Item {
                        anchors.fill: parent
                        visible: root.page === "config"
                        ShellConfig { anchors.fill: parent }
                    }
                    
                    Keys.onEscapePressed: Popups.dashboardOpen = false
                }
            }
        }
    }

    // ── No page components needed — pages are declared inline above ──────────
}
