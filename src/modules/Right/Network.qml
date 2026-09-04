import QtQuick
import "../../components"
import Quickshell.Io
import "../../services"
import "../../"

Item {
    id: root

    property real localScale: 1.0

    implicitWidth:  row.implicitWidth + Math.round(6 * localScale)
    implicitHeight: row.implicitHeight

    property int    _signal:       NetworkService.signal
    property bool   _ethernet:     NetworkService.ethernet
    property string _connectivity: NetworkService.connectivity

    readonly property bool _limited: {
        var c = _connectivity
        return c === "limited" || c === "portal" || c === "none"
    }

    readonly property string _netIcon: {
        if (_ethernet) return _limited ? "󰅢" : ""
        if (_signal <= 0) return "󰤭"
        if (_limited) return ""

        if (_signal > 75) return "󰤨"
        if (_signal > 50) return "󰤥"
        if (_signal > 25) return "󰤢"
        return "󰤟"
    }

    readonly property color _netColor: {
        if (!_ethernet && _signal <= 0) return Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.28)
        if (_connectivity === "none")   return "#f87171"
        if (_limited)                   return "#f5c47a"
        return hov.hovered ? Theme.active : Theme.text
    }

    // VPN blink
    property real _vpnOpacity: 1.0
    SequentialAnimation on _vpnOpacity {
        running: ShellState.vpnConnecting; loops: Animation.Infinite
        NumberAnimation { to: 0.20; duration: Anim.verySlow; easing.type: Anim.inOutSine}
        NumberAnimation { to: 1.0;  duration: Anim.verySlow; easing.type: Anim.inOutSine}
    }
    Connections {
        target: ShellState
        function onVpnConnectingChanged() {
            if (!ShellState.vpnConnecting) root._vpnOpacity = 1.0
        }
    }

    // Polling

    HoverHandler { id: hov; onHoveredChanged: Popups.networkTriggerHovered = hovered }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(4 * localScale)

        // WiFi/ethernet icon — opens to wifi tab
        Text {
            id: netIcon
            text:           root._netIcon
            color:          wifiHov.hovered ? Theme.active : root._netColor
            font.pixelSize: Math.round(16 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Anim.normal} }
            HoverHandler {
                id: wifiHov
                onHoveredChanged: {
                    if (hovered && !Popups.networkPinned) Popups.networkPage = "wifi"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IpcManager.wifiToggle.toggle()
            }
        }

        // VPN shield — opens to vpn tab
        Text {
            visible:        ShellState.vpnActive || ShellState.vpnConnecting
            text:           ShellState.vpnConnecting ? "󱦚" : "󰦝"
            font.pixelSize: Math.round(14 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            opacity:        root._vpnOpacity
            color: ShellState.vpnActive ? Theme.active : (vpHov.hovered ? Theme.active : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.70))
            Behavior on color   { ColorAnimation  { duration: Anim.normal} }
            Behavior on opacity { NumberAnimation { duration: Anim.superFast} }
            HoverHandler {
                id: vpHov
                onHoveredChanged: {
                    if (hovered && !Popups.networkPinned) Popups.networkPage = "vpn"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IpcManager.vpnToggle.toggle()
            }
        }

        // Bluetooth — opens to bluetooth tab
        Text {
            visible:        ShellState.btPowered
            text:           ShellState.btConnected ? "󰂱" : "󰂯"
            font.pixelSize: Math.round(14 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            color: ShellState.btConnected ? (btHov.hovered ? Theme.active : Theme.text) : Qt.rgba(Theme.text.r,Theme.text.g,Theme.text.b,0.32)
            Behavior on color { ColorAnimation { duration: Anim.normal} }
            HoverHandler {
                id: btHov
                onHoveredChanged: {
                    if (hovered && !Popups.networkPinned) Popups.networkPage = "bluetooth"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IpcManager.btToggle.toggle()
            }
        }

        // Hotspot — opens to hotspot tab
        Text {
            visible:        ShellState.hotspot
            text:           "󰀂"
            font.pixelSize: Math.round(14 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            color:          hotspotHov.hovered ? Theme.active : Theme.text
            Behavior on color { ColorAnimation { duration: Anim.normal} }
            HoverHandler {
                id: hotspotHov
                onHoveredChanged: {
                    if (hovered && !Popups.networkPinned) Popups.networkPage = "hotspot"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IpcManager.hotspotToggle.toggle()
            }
        }
    }
}
