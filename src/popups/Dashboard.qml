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

    // ── Context-Aware Scaling ─────────────────────────────────────────────────
    // Multiplier based on screen height relative to 1080p, clamped to prevent
    // extreme scaling on ultra-high or ultra-low resolution displays.
    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int fw: Math.round(Theme.notchRadius * localScale)
    readonly property int fh: Math.round(Theme.notchRadius * localScale)
    readonly property int animDuration: Theme.animDuration

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
        Popups.dashboardPageWidth = _pageWidths[p] ?? 900
    }

    onPageChanged: _applyPageWidth(page)

    readonly property real scaledPageWidth: Math.min(Popups.dashboardPageWidth * localScale, (screen ? screen.width : 1920) * 0.95)

    color:   "transparent"
    visible: windowVisible

    anchors.top:   true
    anchors.left:  true
    anchors.right: true
    anchors.bottom: true

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer:         WlrLayer.Overlay

    property bool wantsFocus: false
    WlrLayershell.keyboardFocus: wantsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: focusGrabTimer
        interval: 15
        onTriggered: if (windowVisible && Popups.dashboardOpen) root.wantsFocus = true
    }

    property bool windowVisible: false

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (Popups.dashboardOpen) {
                closeTimer.stop()
                root.windowVisible = true
                root._applyPageWidth(root.page)
                focusGrabTimer.restart() // Delay the grab slightly
            } else {
                root.wantsFocus = false // Release instantly
                focusGrabTimer.stop()
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

        width:  Popups.dashboardOpen ? root.scaledPageWidth + 2 * root.fw : Theme.cNotchMinWidth + 2 * root.fw
        height: Popups.dashboardOpen 
            ? Math.min(Theme.dashboardHeight * localScale, (screen ? screen.height : 1080) * 0.90) 
            : Theme.notchHeight / 2

        Behavior on width  { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Easing.InOutCubic } }
        
        MouseArea {
            anchors.fill: parent
            onClicked:    {}
        }

        // ── Background ────────────────────────────────────────────────────────
        PopupShape {
            anchors.fill: parent
            attachedEdge: "top"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        // ── Content ───────────────────────────────────────────────────────────
        Item {
            id: content
            anchors {
                fill:         parent
                topMargin:    root.fh + Math.round(8 * localScale)
                leftMargin:   root.fw + Math.round(8 * localScale)
                rightMargin:  root.fw + Math.round(8 * localScale)
                bottomMargin: Math.round(8 * localScale)
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
                    localScale:  root.localScale
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

                // ── Page area ─────────────────────────────────────────────────
                Item {
                    id: pageArea
                    focus: true
                    
                    width:  parent.width
                    height: parent.height - tabBar.height

                    Item {
                        anchors.fill: parent
                        opacity: root.page === "home" ? 1 : 0
                        visible: opacity > 0
                        scale: root.page === "home" ? 1 : 0.98
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        DashHome { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    Item {
                        anchors.fill: parent
                        opacity: root.page === "stats" ? 1 : 0
                        visible: opacity > 0
                        scale: root.page === "stats" ? 1 : 0.98
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        DashStats { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    Item {
                        anchors.fill: parent
                        opacity: root.page === "kanban" ? 1 : 0
                        visible: opacity > 0
                        scale: root.page === "kanban" ? 1 : 0.98
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        KanbanBoard { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    Item {
                        anchors.fill: parent
                        opacity: root.page === "launcher" ? 1 : 0
                        visible: opacity > 0
                        scale: root.page === "launcher" ? 1 : 0.98
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        AppLauncher { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    Item {
                        anchors.fill: parent
                        opacity: root.page === "config" ? 1 : 0
                        visible: opacity > 0
                        scale: root.page === "config" ? 1 : 0.98
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        ShellConfig { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }
                    
                    Keys.onEscapePressed: Popups.dashboardOpen = false
                }
            }
        }
    }
}
