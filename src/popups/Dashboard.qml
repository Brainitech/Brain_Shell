import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../modules/Center/"
import '../services/'
import "../"

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
    readonly property int animDuration: Theme.animDuration

    property string page: "home"

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

    onPageChanged: {
        _applyPageWidth(page)
        if (Popups.dashboardOpen && typeof pageArea !== "undefined") {
            pageArea.forceActiveFocus()
        }
    }
    // ── Surface config ────────────────────────────────────────────────────────
    color:   "transparent"
    visible: windowVisible

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    anchors.bottom: true

    implicitHeight: Theme.notchHeight + Theme.dashboardHeight
    exclusionMode:  ExclusionMode.Ignore

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    // ── Window visibility gate ────────────────────────────────────────────────
    property bool windowVisible: false

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (Popups.dashboardOpen) {
                closeTimer.stop()
                root.windowVisible = true
                root._applyPageWidth(root.page)
                pageArea.forceActiveFocus()
            } else {
                closeTimer.restart()
            }
        }
    }
    
    // ── IPC handlers for external toggle requests ─────────────────────────────
    IpcHandler {
        target: "dashboard-home"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                root.page = "home"
            } else if(Popups.dashboardOpen && root.page != "home") {
                root.page = "home"
            } else if(Popups.dashboardOpen && root.page == "home") {
                Popups.dashboardOpen = false
            } else {
                Popups.dashboardOpen = !Popups.dashboardOpen
                root.page = "home"
            }
        }
    }
    IpcHandler {
        target: "dashboard-stats"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                root.page = "stats"
            } else if(Popups.dashboardOpen && root.page != "stats") {
                root.page = "stats"
            } else if(Popups.dashboardOpen && root.page == "stats") {
                Popups.dashboardOpen = false
            } else {
                Popups.dashboardOpen = !Popups.dashboardOpen
                root.page = "stats"
            }
        }
    }
    IpcHandler {
        target: "dashboard-kanban"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                root.page = "kanban"
            } else if(Popups.dashboardOpen && root.page != "kanban") {
                root.page = "kanban"
            } else if(Popups.dashboardOpen && root.page == "kanban") {
                Popups.dashboardOpen = false
            } else {
                Popups.dashboardOpen = !Popups.dashboardOpen
                root.page = "kanban"
            }
        }
    }
    IpcHandler {
        target: "dashboard-launcher"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                root.page = "launcher"
            } else if(Popups.dashboardOpen && root.page != "launcher") {
                root.page = "launcher"
            } else if(Popups.dashboardOpen && root.page == "launcher") {
                Popups.dashboardOpen = false
            } else {
                Popups.dashboardOpen = !Popups.dashboardOpen
                root.page = "launcher"
            }
        }
    }
    IpcHandler {
        target: "dashboard-config"
        function toggle() {
            if(Popups.anyOpen && !Popups.dashboardOpen){
                Popups.closeAll()
                Popups.dashboardOpen = true
                root.page = "config"
            } else if(Popups.dashboardOpen && root.page != "config") {
                root.page = "config"
            } else if(Popups.dashboardOpen && root.page == "config") {
                Popups.dashboardOpen = false
            } else {
                Popups.dashboardOpen = !Popups.dashboardOpen
                root.page = "config"
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

    Item {
        anchors.fill: parent
        TapHandler {
            onTapped: Popups.dashboardOpen = false // or wallpaperOpen = false
        }
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

        Behavior on width  { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }

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
                    id: pageArea
                    focus: true
                    
                    width:  parent.width
                    height: parent.height - tabBar.height

                    Item {
                        anchors.fill: parent
                        visible:      root.page === "home"
                        DashHome { anchors.fill: parent }
                    }

                    Item {
                        anchors.fill: parent
                        visible:      root.page === "stats"
                        DashStats { anchors.fill: parent }
                    }

                    Item {
                        anchors.fill: parent
                        visible:      root.page === "kanban"
                        KanbanBoard { anchors.fill: parent }
                    }

                    Item {
                        anchors.fill: parent
                        visible:      root.page === "launcher"
                        AppLauncher { anchors.fill: parent }
                    }

                    Item {
                        anchors.fill: parent
                        visible:      root.page === "config"
                        Item {
                            anchors.fill: parent
                            visible:      root.page === "config"
                            ShellConfig { anchors.fill: parent }
                        }
                    }
                    
                    Keys.onEscapePressed: Popups.dashboardOpen = false
                }
            }
        }
    }
}
