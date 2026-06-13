import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shapes"
import "../components"
import "../theme"
import "../"

PanelWindow {
    id: root

    readonly property int popupWidth:  Theme.networkPopupWidth   // 480
    readonly property int popupHeight: 648
    readonly property int fw:          Theme.notchRadius
    readonly property int fh:          Theme.notchRadius

    property string page: Popups.networkPage

    anchors.right: true
    anchors.top:   true

    // Window height = popup content only — sizer starts at y:0
    implicitWidth:  popupWidth + fw
    implicitHeight: popupHeight

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
        interval: Anim.standardNormal + 20
        onTriggered: { if (!Popups.networkOpen) root.windowVisible = false }
    }

    // ── Sizer — clip container, grows downward from y:0 ──────────────────────
    Item {
        id: sizer
        anchors.right: parent.right
        anchors.rightMargin: Theme.borderWidth
        y: 0
        clip: true

        width: Popups.networkOpen
               ? root.popupWidth + 9
               : Theme.rNotchMinWidth + root.fw

        height: Popups.networkOpen ? root.popupHeight : 1

        Behavior on width  { NumberAnimation { duration: Anim.standardNormal; easing: Anim.outCubic } }
        Behavior on height { NumberAnimation { duration: Anim.standardNormal; easing: Anim.outCubic } }

        PopupShape {
            anchors.fill: parent
            attachedEdge: "right"
            color:        Theme.background
            radius:       Theme.cornerRadius
            flareWidth:   root.fw
            flareHeight:  root.fh
        }
        
        Keys.onEscapePressed: Popups.networkOpen = false

        ShellPopupBase {
            id: contentArea
            anchors {
                fill:         parent
                topMargin:    Theme.notchHeight
                leftMargin:   root.fw
                rightMargin:  root.fw/2
                bottomMargin: root.fh + Theme.cornerRadius
            }
            isOpen: Popups.networkOpen
            transformEdge: "right"
            disableAutoHide: true
            clip: true
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
                    active:       root.page === "wifi"
                    source:       "WifiTab.qml"
                }

                Loader {
                    anchors.fill: parent
                    active:       root.page === "bluetooth"
                    source:       "BluetoothTab.qml"
                }

                // VPN — WireGuard connections
                Loader {
                    anchors.fill: parent
                    active:       root.page === "vpn"
                    source:       "VPNTab.qml"
                }

                // Hotspot — virtual AP interface
                Loader {
                    anchors.fill: parent
                    active:       root.page === "hotspot"
                    source:       "HotspotTab.qml"
                }
            }

            // ── Tab bar — lifted by cornerRadius from the popup bottom ────────
            TabSwitcher {
                id: tabBar
                anchors {
                    left:         parent.left
                    right:        parent.right
                    bottom:       parent.bottom
                    bottomMargin: -16
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
