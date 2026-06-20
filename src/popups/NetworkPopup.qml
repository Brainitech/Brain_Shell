import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../"

PanelWindow {
    id: root

    readonly property real localScale: Math.max(0.75, Math.min(1.5, (screen ? screen.height : 1080.0) / 1080.0))

    readonly property int popupWidth:  Math.round(Theme.networkPopupWidth * root.localScale)
    readonly property int popupHeight: Math.round(648 * root.localScale)
    readonly property int fw:          Math.round(Theme.notchRadius * root.localScale)
    readonly property int fh:          Math.round(Theme.notchRadius * root.localScale)

    property string page: Popups.networkPage

    anchors.right: true
    anchors.top:   true

    // Window height = popup content only — sizer starts at y:0
    implicitWidth:  popupWidth + fw + 8
    implicitHeight: popupHeight + 8

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Mask tracks sizer — limits input region to visible content only
    mask: Region { item: maskProxy }

    Item {
        id: maskProxy
        x:      root.implicitWidth - sizer.width
        y:      0
        width:  sizer.width
        height: sizer.height
    }

    // ── Visibility gate ───────────────────────────────────────────────────────
    property bool windowVisible: false
    visible: windowVisible

    Connections {
        target: Popups
        function onNetworkOpenChanged() {
            if (Popups.networkOpen) {
                closeTimer.stop()
                root.windowVisible = true
                // Use requested page if set, otherwise default to wifi
                root.page = (Popups.networkPage && Popups.networkPage !== "")
                    ? Popups.networkPage : "wifi"
            } else {
                closeTimer.restart()
            }
        }

        function onNetworkPageChanged() {
            root.page = Popups.networkPage
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.animDuration + 20
        onTriggered: { if (!Popups.networkOpen) root.windowVisible = false }
    }

    // ── Sizer — clip container, grows downward from y:0 ──────────────────────
    Item {
        id: sizer
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        y: 0
        clip: true

        width: Popups.networkOpen
       ? root.popupWidth + root.fw
       : Math.round(Theme.rNotchMinWidth * root.localScale) + root.fw

        height: Popups.networkOpen ? root.popupHeight : 0

        Behavior on width  { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "right"
            color:        Theme.background
            radius:       Math.round(Theme.cornerRadius * root.localScale)
            flareWidth:   root.fw
            flareHeight:  root.fh
        }

        Keys.onEscapePressed: Popups.networkOpen = false

        Item {
            id: contentArea
            anchors {
                fill:         parent
                topMargin:    Math.round(Theme.notchHeight * root.localScale)
                leftMargin:   root.fw
                rightMargin:  root.fw/2
                bottomMargin: root.fh + Math.round(Theme.cornerRadius * root.localScale)
            }

            opacity: Popups.networkOpen ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Popups.networkOpen
                        ? Theme.animDuration * 0.5
                        : Theme.animDuration * 0.15
                }
            }

            // ── Tab page area ─────────────────────────────────────────────────
            Item {
                id: tabContent
                anchors {
                    top:    parent.top
                    left:   parent.left
                    right:  parent.right
                    bottom: tabBar.top
                }

                Loader {
                    anchors.fill: parent
                    property bool isCurrent: root.page === "wifi"
                    active:       isCurrent || opacity > 0
                    opacity:      isCurrent ? 1 : 0
                    scale:        isCurrent ? 1 : 0.98
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    source:       "WifiTab.qml"
                    onLoaded:     item.localScale = root.localScale
                }

                Loader {
                    anchors.fill: parent
                    property bool isCurrent: root.page === "bluetooth"
                    active:       isCurrent || opacity > 0
                    opacity:      isCurrent ? 1 : 0
                    scale:        isCurrent ? 1 : 0.98
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    source:       "BluetoothTab.qml"
                    onLoaded:     item.localScale = root.localScale
                }

                // VPN — WireGuard connections
                Loader {
                    anchors.fill: parent
                    property bool isCurrent: root.page === "vpn"
                    active:       isCurrent || opacity > 0
                    opacity:      isCurrent ? 1 : 0
                    scale:        isCurrent ? 1 : 0.98
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    source:       "VPNTab.qml"
                    onLoaded:     item.localScale = root.localScale
                }

                // Hotspot — virtual AP interface
                Loader {
                    anchors.fill: parent
                    property bool isCurrent: root.page === "hotspot"
                    active:       isCurrent || opacity > 0
                    opacity:      isCurrent ? 1 : 0
                    scale:        isCurrent ? 1 : 0.98
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    source:       "HotspotTab.qml"
                    onLoaded:     item.localScale = root.localScale
                }
            }

            // ── Tab bar — lifted by cornerRadius from the popup bottom ────────
            TabSwitcher {
                id: tabBar
                localScale: root.localScale || 1.0
                anchors {
                left:         parent.left
                right:        parent.right
                bottom:       parent.bottom
                bottomMargin: Math.round(-16 * root.localScale)
            }
                orientation: "horizontal"
                width:        parent.width
                currentPage:  root.page
                model: [
                    { key: "wifi",      icon: "󰤨", label: "Wi-Fi"     },
                    { key: "bluetooth", icon: "󰂯", label: "Bluetooth" },
                    { key: "vpn",       icon: "󰦝", label: "VPN"       },
                    { key: "hotspot",   icon: "󰀃", label: "Hotspot"   },
                ]
                onPageChanged: function(key) { Popups.networkPage = key }
            }
        }
    }
}
