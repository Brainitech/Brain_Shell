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

Item {
    id: root
    Keys.onEscapePressed: if (!Popups.colorPickerActive) SurfaceState.close()
    onOpacityChanged: { if (opacity === 1 && Popups.dashboardPage !== "launcher") forceActiveFocus() }

    property var screen

    // ── Context-Aware Scaling ─────────────────────────────────────────────────
    // Multiplier based on screen height relative to 1080p, clamped to prevent
    // extreme scaling on ultra-high or ultra-low resolution displays.
    property real localScale: 1.0

    readonly property int fw: Math.round(Theme.notchRadius * localScale)
    readonly property int fh: Math.round(Theme.notchRadius * localScale)
    readonly property int animDuration: Anim.transition

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

    property bool wantsFocus: false

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
        function onDashboardTriggerHoveredChanged() {
            if (Popups.dashboardTriggerHovered) {
                if (root.allowHover) {
                    hoverCloseTimer.stop()
                    hoverOpenTimer.restart()
                }
            } else {
                hoverOpenTimer.stop()
                if (root.allowHover && !root.selfHovered) hoverCloseTimer.restart()
            }
        }
    }

    property bool allowHover: Popups.dashboardAllowHover
    property bool pinned:     Popups.dashboardPinned
    property bool selfHovered: false

    onSelfHoveredChanged: {
        if (root.allowHover) {
            if (!selfHovered && !Popups.dashboardTriggerHovered && !Popups.colorPickerActive) hoverCloseTimer.restart()
            else                                                 hoverCloseTimer.stop()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Popups.hoverOpenDelay
        onTriggered: {
            if (root.allowHover && Popups.dashboardTriggerHovered) {
                if (!Popups.dashboardOpen) {
                    Popups.closeAll()
                    SurfaceState.open("top", "dashboard")
                }
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (root.allowHover && !Popups.dashboardTriggerHovered && !root.selfHovered && !Popups.colorPickerActive) {
                if (!root.pinned) {
                    SurfaceState.close()
                }
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





    // ── Sizer ─────────────────────────────────────────────────────────────────
    // topMargin: Theme.notchHeight places the sizer top exactly at the notch
    // bottom — identical to where PopupWindow put it. No fh subtraction, which
    // was the source of the vertical offset in the text-working variant.
    Item {
        id: hoverContainer
        MouseArea { anchors.fill: parent }
        anchors.fill: parent

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        Item {
            id: sizer
            anchors.fill: parent
            clip: true
            


        // ── Content ───────────────────────────────────────────────────────────
        Item {
            id: content
            anchors {
                fill:         parent
                topMargin:    Math.round(8 * localScale)
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
                    clip:  true
                    
                    width:  parent.width
                    height: parent.height - tabBar.height
                    
                    property int pageIdx: Math.max(0, ["home", "stats", "kanban", "launcher", "config"].indexOf(root.page))
                    
                    property int oldIdx: pageIdx
                    property int newIdx: pageIdx
                    property real progress: 1.0
                    
                    NumberAnimation {
                        id: progressAnim
                        target: pageArea
                        property: "progress"
                        from: 0.0
                        to: 1.0
                        duration: Anim.style === "none" ? 0 : Anim.transition
                        easing.type: Anim.outCubic
                    }
                    
                    onPageIdxChanged: {
                        oldIdx = newIdx;
                        newIdx = pageIdx;
                        progress = 0.0;
                        if (Anim.style !== "none") progressAnim.restart();
                        else progress = 1.0;
                    }

                    component SlidePage: Item {
                        property int myIdx
                        property bool isCurrent: myIdx === pageArea.pageIdx
                        property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                        
                        property bool isIncoming: myIdx === pageArea.newIdx
                        property bool isOutgoing: myIdx === pageArea.oldIdx
                        property int slideDir: pageArea.newIdx > pageArea.oldIdx ? 1 : -1
                        
                        width: parent.width; height: parent.height
                        
                        x: {
                            if (Anim.style === "none") return 0;
                            if (isIncoming) {
                                return slideDir * root.scaledPageWidth * (1.0 - pageArea.progress);
                            } else if (isOutgoing) {
                                return -slideDir * root.scaledPageWidth * parallaxFactor * pageArea.progress;
                            } else {
                                return myIdx < pageArea.newIdx ? -root.scaledPageWidth : root.scaledPageWidth;
                            }
                        }
                        
                        opacity: {
                            if (Anim.style !== "parallax") return 1.0;
                            if (isIncoming) return pageArea.progress;
                            if (isOutgoing) return 1.0 - pageArea.progress;
                            return 0.0;
                        }
                        
                        visible: isCurrent || (isOutgoing && pageArea.progress < 1.0)
                    }

                    SlidePage {
                        myIdx: 0
                        DashHome { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    SlidePage {
                        myIdx: 1
                        DashStats { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    SlidePage {
                        myIdx: 2
                        KanbanBoard { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    SlidePage {
                        myIdx: 3
                        AppLauncher { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    SlidePage {
                        myIdx: 4
                        ShellConfig { 
                            anchors.fill: parent 
                            localScale:   root.localScale
                        }
                    }

                    Keys.onEscapePressed: if (!Popups.colorPickerActive) SurfaceState.close()
                }
            }
        }
        }
    }
}
