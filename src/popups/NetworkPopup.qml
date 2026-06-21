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
        height: Math.max(sizer.height, Math.round(Theme.notchHeight * root.localScale))
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

        function onNetworkTriggerHoveredChanged() {
            if (Popups.networkTriggerHovered) {
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

    property bool allowHover: Popups.networkAllowHover
    property bool pinned:     Popups.networkPinned
    property bool selfHovered: false

    onSelfHoveredChanged: {
        if (root.allowHover) {
            if (!selfHovered && !Popups.networkTriggerHovered) hoverCloseTimer.restart()
            else                                               hoverCloseTimer.stop()
        }
    }

    Timer {
        id: hoverOpenTimer
        interval: Popups.hoverOpenDelay
        onTriggered: {
            if (root.allowHover && Popups.networkTriggerHovered) {
                if (!Popups.networkOpen) {
                    Popups.closeAll()
                    Popups.networkOpen = true
                }
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: Popups.hoverCloseDelay
        onTriggered: {
            if (root.allowHover && !Popups.networkTriggerHovered && !root.selfHovered) {
                if (!root.pinned) {
                    Popups.networkOpen = false
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Anim.transition + 20
        onTriggered: { if (!Popups.networkOpen) root.windowVisible = false }
    }

    // ── Sizer — clip container, grows downward from y:0 ──────────────────────
    Item {
        id: hoverContainer
        anchors.right: parent.right
        anchors.rightMargin: Math.round(Theme.borderWidth * root.localScale)
        y: 0
        width: sizer.width
        height: Math.max(sizer.height, Math.round(Theme.notchHeight * root.localScale))

        HoverHandler {
            onHoveredChanged: root.selfHovered = hovered
        }

        Item {
            id: sizer
            anchors.top: parent.top
            anchors.right: parent.right
            clip: true
            
            TapHandler {
                onTapped: {
                    Popups.networkOpen = true
                    Popups.networkPinned = true
                }
            }

            width: Popups.networkOpen ? root.popupWidth + root.fw : Math.round(Theme.rNotchMinWidth * root.localScale) + root.fw

            TapHandler {
                onTapped: {
                    Popups.networkOpen = true
                    Popups.networkPinned = true
                }
            }

            height: Popups.networkOpen ? root.popupHeight : 0
    
            Behavior on width  { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
            Behavior on height { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
    
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
                            ? Anim.transition * 0.5
                            : Anim.transition * 0.15
                    }
                }
    
                // ── Tab page area ─────────────────────────────────────────────────
                Item {
                    id: tabContent
                    clip: true
                    
                    property int pageIdx: Math.max(0, ["wifi", "bluetooth", "vpn", "hotspot"].indexOf(root.page))
    
                    anchors {
                        top:    parent.top
                        left:   parent.left
                        right:  parent.right
                        bottom: tabBar.top
                    }
    
                    Loader {
                        id: tabWifi
                        readonly property int myIdx: 0
                        property bool isCurrent: root.page === "wifi"
                        property bool wasCurrent: false
                        property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                        onIsCurrentChanged: { 
                            if (isCurrent) wasCurrent = false;
                            else if (Anim.style === "none") wasCurrent = false;
                            else wasCurrent = true;
                        }
                        
                        width: parent.width; height: parent.height
                        
                        property real targetX: {
                            if (Anim.style === "none") return 0;
                            if (isCurrent) return 0;
                            if (myIdx < tabContent.pageIdx) return -width * parallaxFactor;
                            return width;
                        }
                        
                        x: targetX
                        Behavior on x {
                            enabled: Anim.style !== "none"
                            NumberAnimation { 
                                duration: Anim.slow; easing.type: Anim.outExpo
                                onRunningChanged: { if (!running && !tabWifi.isCurrent) tabWifi.wasCurrent = false; }
                            }
                        }
                        
                        property real targetOpacity: {
                            if (Anim.style !== "parallax") return 1.0;
                            if (isCurrent) return 1.0;
                            return 0.0;
                        }
                        opacity: targetOpacity
                        Behavior on opacity {
                            enabled: Anim.style === "parallax"
                            NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                        }
                        
                        active: isCurrent || wasCurrent
                        visible: active
                        
                        source:       "WifiTab.qml"
                        onLoaded:     item.localScale = root.localScale
                    }
    
                    Loader {
                        id: tabBluetooth
                        readonly property int myIdx: 1
                        property bool isCurrent: root.page === "bluetooth"
                        property bool wasCurrent: false
                        property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                        onIsCurrentChanged: { 
                            if (isCurrent) wasCurrent = false;
                            else if (Anim.style === "none") wasCurrent = false;
                            else wasCurrent = true;
                        }
                        
                        width: parent.width; height: parent.height
                        
                        property real targetX: {
                            if (Anim.style === "none") return 0;
                            if (isCurrent) return 0;
                            if (myIdx < tabContent.pageIdx) return -width * parallaxFactor;
                            return width;
                        }
                        
                        x: targetX
                        Behavior on x {
                            enabled: Anim.style !== "none"
                            NumberAnimation { 
                                duration: Anim.slow; easing.type: Anim.outExpo
                                onRunningChanged: { if (!running && !tabBluetooth.isCurrent) tabBluetooth.wasCurrent = false; }
                            }
                        }
                        
                        property real targetOpacity: {
                            if (Anim.style !== "parallax") return 1.0;
                            if (isCurrent) return 1.0;
                            return 0.0;
                        }
                        opacity: targetOpacity
                        Behavior on opacity {
                            enabled: Anim.style === "parallax"
                            NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                        }
                        
                        active: isCurrent || wasCurrent
                        visible: active
                        
                        source:       "BluetoothTab.qml"
                        onLoaded:     item.localScale = root.localScale
                    }
    
                    // VPN — WireGuard connections
                    Loader {
                        id: tabVpn
                        readonly property int myIdx: 2
                        property bool isCurrent: root.page === "vpn"
                        property bool wasCurrent: false
                        property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                        onIsCurrentChanged: { 
                            if (isCurrent) wasCurrent = false;
                            else if (Anim.style === "none") wasCurrent = false;
                            else wasCurrent = true;
                        }
                        
                        width: parent.width; height: parent.height
                        
                        property real targetX: {
                            if (Anim.style === "none") return 0;
                            if (isCurrent) return 0;
                            if (myIdx < tabContent.pageIdx) return -width * parallaxFactor;
                            return width;
                        }
                        
                        x: targetX
                        Behavior on x {
                            enabled: Anim.style !== "none"
                            NumberAnimation { 
                                duration: Anim.slow; easing.type: Anim.outExpo
                                onRunningChanged: { if (!running && !tabVpn.isCurrent) tabVpn.wasCurrent = false; }
                            }
                        }
                        
                        property real targetOpacity: {
                            if (Anim.style !== "parallax") return 1.0;
                            if (isCurrent) return 1.0;
                            return 0.0;
                        }
                        opacity: targetOpacity
                        Behavior on opacity {
                            enabled: Anim.style === "parallax"
                            NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                        }
                        
                        active: isCurrent || wasCurrent
                        visible: active
                        
                        source:       "VPNTab.qml"
                        onLoaded:     item.localScale = root.localScale
                    }
    
                    // Hotspot — virtual AP interface
                    Loader {
                        id: tabHotspot
                        readonly property int myIdx: 3
                        property bool isCurrent: root.page === "hotspot"
                        property bool wasCurrent: false
                        property real parallaxFactor: Anim.style === "parallax" ? 0.3 : 1.0
                        onIsCurrentChanged: { 
                            if (isCurrent) wasCurrent = false;
                            else if (Anim.style === "none") wasCurrent = false;
                            else wasCurrent = true;
                        }
                        
                        width: parent.width; height: parent.height
                        
                        property real targetX: {
                            if (Anim.style === "none") return 0;
                            if (isCurrent) return 0;
                            if (myIdx < tabContent.pageIdx) return -width * parallaxFactor;
                            return width;
                        }
                        
                        x: targetX
                        Behavior on x {
                            enabled: Anim.style !== "none"
                            NumberAnimation { 
                                duration: Anim.slow; easing.type: Anim.outExpo
                                onRunningChanged: { if (!running && !tabHotspot.isCurrent) tabHotspot.wasCurrent = false; }
                            }
                        }
                        
                        property real targetOpacity: {
                            if (Anim.style !== "parallax") return 1.0;
                            if (isCurrent) return 1.0;
                            return 0.0;
                        }
                        opacity: targetOpacity
                        Behavior on opacity {
                            enabled: Anim.style === "parallax"
                            NumberAnimation { duration: Anim.slow; easing.type: Anim.outExpo }
                        }
                        
                        active: isCurrent || wasCurrent
                        visible: active
                        
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
}