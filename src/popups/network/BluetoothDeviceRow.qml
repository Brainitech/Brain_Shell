/*
 * Brain Shell
 * Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import "../../"

Item {
    id: dRow

    property real localScale: 1.0
    property var  device: ({ mac: "", name: "", paired: false, connected: false, iconType: "default" })
    property bool isPaired: false

    readonly property bool isConnected: device ? device.connected : false
    property bool inAction: false
    property bool inRemove: false
    property bool isPairingOpen: false
    property bool isRemovePending: false

    signal connectClicked(string mac)
    signal disconnectClicked(string mac)
    signal toggleRemove(string mac)
    signal cancelRemove()
    signal confirmRemove(string mac)
    signal togglePairing(string mac)
    signal cancelPairing()
    signal confirmPair(string mac, string pin)

    function glyphFor(iconType) {
        switch(iconType) {
            case "headphone": return "󰋋"
            case "speaker":   return "󰓃"
            case "keyboard":  return "󰌌"
            case "mouse":     return "󰍽"
            case "phone":     return "󰄜"
            case "laptop":    return "󰌢"
            case "watch":     return "󰢗"
            case "gamepad":   return "󰊖"
            case "tv":        return "󰔮"
            default:          return "󰂯"
        }
    }

    width: parent ? parent.width : 0
    height: baseRow.height + expandArea.height

    Rectangle {
        anchors.fill: parent
        radius: Math.round(Theme.cornerRadius * localScale)
        color: dRow.isConnected
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
            : rowHov.hovered && !dRow.isPaired ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
        border.color: dRow.isConnected
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
            : dRow.isRemovePending ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
        border.width: Math.max(1, Math.round(1 * localScale))
        Behavior on color        { ColorAnimation { duration: Anim.color } }
        Behavior on border.color { ColorAnimation { duration: Anim.color } }
    }

    Item {
        id: baseRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.round(50 * localScale)

        Text {
            anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
            text: dRow.glyphFor(dRow.device ? dRow.device.iconType : "default")
            font.pixelSize: Math.round(18 * localScale)
            color: dRow.isConnected
                ? Theme.active
                : (dRow.inAction || dRow.inRemove)
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.5)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.32)
            Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
        }

        Column {
            anchors { left: parent.left; leftMargin: Math.round(44 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(3 * localScale)

            Text {
                text: dRow.device ? dRow.device.name : ""
                font.pixelSize: Math.round(13 * localScale)
                font.weight: dRow.isConnected ? Font.Medium : Font.Normal
                color: dRow.isConnected ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.68)
                width: Math.round(160 * localScale)
                elide: Text.ElideRight
            }

            Text {
                visible: dRow.isConnected || dRow.inAction || dRow.inRemove
                text: dRow.inRemove ? "Removing…" : dRow.inAction ? "Working…" : "Connected"
                font.pixelSize: Math.round(10 * localScale)
                color: (dRow.inAction || dRow.inRemove) ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Theme.active
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(6 * localScale)

            // Spinner
            Text {
                visible: dRow.inAction || dRow.inRemove
                text: "○"
                font.pixelSize: Math.round(15 * localScale)
                color: Theme.active
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    running: dRow.inAction || dRow.inRemove
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: Anim.slower }
                    NumberAnimation { to: 1.0;  duration: Anim.slower }
                }
            }

            // Paired: connect/disconnect pill
            Rectangle {
                visible: dRow.isPaired && !dRow.inAction && !dRow.inRemove
                anchors.verticalCenter: parent.verticalCenter
                width: togContent.implicitWidth + Math.round(20 * localScale)
                height: Math.round(28 * localScale)
                radius: Math.round(14 * localScale)
                color: dRow.isConnected
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                    : togH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                border.color: dRow.isConnected
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.36)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.11)
                border.width: Math.max(1, Math.round(1 * localScale))
                Behavior on color { ColorAnimation { duration: Anim.color } }

                Row {
                    id: togContent
                    anchors.centerIn: parent
                    spacing: Math.round(7 * localScale)

                    Rectangle {
                        width: Math.round(7 * localScale)
                        height: Math.round(7 * localScale)
                        radius: Math.round(4 * localScale)
                        anchors.verticalCenter: parent.verticalCenter
                        color: dRow.isConnected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                        Behavior on color { ColorAnimation { duration: Anim.mediumFast } }
                    }

                    Text {
                        text: dRow.isConnected ? "Connected" : "Connect"
                        font.pixelSize: Math.round(11 * localScale)
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                        color: dRow.isConnected ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.48)
                        Behavior on color { ColorAnimation { duration: Anim.color } }
                    }
                }

                HoverHandler { id: togH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: dRow.isConnected
                        ? dRow.disconnectClicked(dRow.device.mac)
                        : dRow.connectClicked(dRow.device.mac)
                }
            }

            // Paired: remove button
            Item {
                visible: dRow.isPaired && !dRow.inAction && !dRow.inRemove
                width: Math.round(28 * localScale)
                height: Math.round(28 * localScale)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(7 * localScale)
                    color: rmH.hovered
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20)
                        : dRow.isRemovePending ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰗼"
                    font.pixelSize: Math.round(13 * localScale)
                    color: (rmH.hovered || dRow.isRemovePending) ? Theme.error : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }

                HoverHandler { id: rmH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: dRow.toggleRemove(dRow.device.mac)
                }
            }

            // Available: Pair + PIN icon
            Row {
                visible: !dRow.isPaired && !dRow.inAction
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(6 * localScale)

                Rectangle {
                    width: pairLbl.implicitWidth + Math.round(20 * localScale)
                    height: Math.round(28 * localScale)
                    radius: Math.round(8 * localScale)
                    color: pairH.hovered
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                        : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.09)
                    border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Text {
                        id: pairLbl
                        anchors.centerIn: parent
                        text: "Pair"
                        font.pixelSize: Math.round(11 * localScale)
                        font.weight: Font.Medium
                        color: Theme.active
                    }

                    HoverHandler { id: pairH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dRow.confirmPair(dRow.device.mac, "")
                    }
                }

                Item {
                    width: Math.round(24 * localScale)
                    height: Math.round(28 * localScale)
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(6 * localScale)
                        color: pinH.hovered
                            ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                            : dRow.isPairingOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        border.color: dRow.isPairingOpen ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09)
                        border.width: Math.max(1, Math.round(1 * localScale))
                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰌾"
                        font.pixelSize: Math.round(12 * localScale)
                        color: dRow.isPairingOpen
                            ? Theme.active
                            : pinH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.28)
                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                    }

                    HoverHandler { id: pinH; cursorShape: Qt.PointingHandCursor }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dRow.togglePairing(dRow.device.mac)
                    }
                }
            }
        }
    }

    // Expandable
    Item {
        id: expandArea
        anchors { top: baseRow.bottom; left: parent.left; right: parent.right }
        clip: true
        height: dRow.isRemovePending
            ? removeRow.implicitHeight + Math.round(16 * localScale)
            : dRow.isPairingOpen
                ? pinRow.implicitHeight + Math.round(16 * localScale)
                : 0
        Behavior on height {
            NumberAnimation {
                duration: Anim.normal
                easing.type: Anim.outCubic
                easing.overshoot: Anim.globalOvershoot
                easing.amplitude: Anim.globalAmplitude
                easing.period: Anim.globalPeriod
            }
        }

        // Remove confirmation
        Item {
            id: removeRow
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
            implicitHeight: Math.round(32 * localScale)
            opacity: dRow.isRemovePending ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Anim.color } }

            Rectangle {
                anchors { fill: parent; leftMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
                radius: Math.round(8 * localScale)
                color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.06)
                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22)
                border.width: Math.max(1, Math.round(1 * localScale))

                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(12 * localScale)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Remove this device?"
                        font.pixelSize: Math.round(11 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                    }

                    Rectangle {
                        width: Math.round(58 * localScale)
                        height: Math.round(24 * localScale)
                        radius: Math.round(6 * localScale)
                        color: cxH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: Math.round(10 * localScale)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.42)
                        }
                        HoverHandler { id: cxH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dRow.cancelRemove()
                        }
                    }

                    Rectangle {
                        width: Math.round(64 * localScale)
                        height: Math.round(24 * localScale)
                        radius: Math.round(6 * localScale)
                        color: rxH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.40) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            anchors.centerIn: parent
                            text: "Remove"
                            font.pixelSize: Math.round(10 * localScale)
                            font.weight: Font.Medium
                            color: Theme.error
                        }
                        HoverHandler { id: rxH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dRow.confirmRemove(dRow.device.mac)
                        }
                    }
                }
            }
        }

        // PIN row
        Item {
            id: pinRow
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
            implicitHeight: pinCol.implicitHeight
            opacity: dRow.isPairingOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Anim.color } }

            Column {
                id: pinCol
                anchors { left: parent.left; right: parent.right; leftMargin: Math.round(8 * localScale); rightMargin: Math.round(8 * localScale) }
                spacing: Math.round(6 * localScale)

                Text {
                    width: parent.width
                    text: "Legacy PIN pairing — enter the PIN shown on your device"
                    font.pixelSize: Math.round(10 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: Math.round(8 * localScale)

                    Rectangle {
                        width: parent.width - pairConfBtn.width - parent.spacing
                        height: Math.round(32 * localScale)
                        radius: Math.round(8 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                        border.color: pinInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                        border.width: Math.max(1, Math.round(1 * localScale))
                        Behavior on border.color { ColorAnimation { duration: Anim.color } }

                        Text {
                            anchors { left: parent.left; leftMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                            text: "PIN (optional)…"
                            font.pixelSize: Math.round(12 * localScale)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.22)
                            visible: pinInput.text === ""
                        }

                        TextInput {
                            id: pinInput
                            anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: Math.round(12 * localScale)
                            font.family: "JetBrains Mono"
                            inputMethodHints: Qt.ImhDigitsOnly
                            maximumLength: 8
                            selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                            clip: true
                            onActiveFocusChanged: Popups.isInputFocused = activeFocus
                            Keys.onReturnPressed: dRow.confirmPair(dRow.device.mac, text)
                            Keys.onEscapePressed: function(event) {
                                event.accepted = true
                                pinInput.text = ""
                                dRow.cancelPairing()
                            }
                        }
                    }

                    Rectangle {
                        id: pairConfBtn
                        width: Math.round(64 * localScale)
                        height: Math.round(32 * localScale)
                        radius: Math.round(8 * localScale)
                        color: pcH.hovered ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                        border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.42)
                        border.width: Math.max(1, Math.round(1 * localScale))
                        Behavior on color { ColorAnimation { duration: Anim.fast } }

                        Text {
                            anchors.centerIn: parent
                            text: "Pair"
                            font.pixelSize: Math.round(11 * localScale)
                            font.weight: Font.Medium
                            color: Theme.active
                        }

                        HoverHandler { id: pcH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dRow.confirmPair(dRow.device.mac, pinInput.text)
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible && dRow.isPairingOpen)
                Qt.callLater(function() { pinInput.forceActiveFocus() })
        }
    }

    onIsPairingOpenChanged: {
        if (isPairingOpen)
            Qt.callLater(function() { pinInput.forceActiveFocus() })
        else
            pinInput.text = ""
    }

    HoverHandler { id: rowHov; enabled: !dRow.isPaired }
}
