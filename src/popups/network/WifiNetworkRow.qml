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
import "../../services"

Item {
    id: netRow

    property real localScale: 1.0
    property var  net: ({ ssid: "", signal: 0, secured: false, inUse: false })
    property bool isCurrent: false
    property bool isForgetPending: false
    property bool isExpanded: false
    property bool isConnecting: false
    property bool needsPassword: false
    property bool _showPass: false

    signal connectClicked(string ssid, string password)
    signal disconnectClicked()
    signal toggleForget(string ssid)
    signal cancelForget()
    signal confirmForget(string ssid)
    signal cancelExpand()

    width: parent ? parent.width : 0
    height: baseRow.height + expandArea.height

    component SignalBars: Item {
        id: barsRoot
        property int signal: 0
        property real localScale: 1.0
        width: Math.round(18 * localScale)
        height: Math.round(14 * localScale)

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(2 * localScale)

            Repeater {
                model: 4
                delegate: Rectangle {
                    required property int index
                    width: Math.round(3 * localScale)
                    height: Math.round((4 + index * 3) * localScale)
                    radius: Math.max(1, Math.round(1 * localScale))
                    anchors.bottom: parent ? parent.bottom : undefined

                    readonly property bool lit: {
                        switch (index) {
                            case 0: return barsRoot.signal > 0
                            case 1: return barsRoot.signal > 25
                            case 2: return barsRoot.signal > 50
                            case 3: return barsRoot.signal > 75
                        }
                        return false
                    }

                    color: lit
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.85)
                        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(Theme.cornerRadius * localScale)
        color: netRow.isCurrent
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.07)
            : rHov.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04) : "transparent"
        border.color: netRow.isCurrent
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.18)
            : netRow.needsPassword
                ? Qt.rgba(245/255, 196/255, 122/255, 0.30)
                : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
        border.width: Math.max(1, Math.round(1 * localScale))
        Behavior on color        { ColorAnimation { duration: Anim.color } }
        Behavior on border.color { ColorAnimation { duration: Anim.color } }
    }

    Item {
        id: baseRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.round(48 * localScale)

        Column {
            anchors { left: parent.left; leftMargin: Math.round(12 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(3 * localScale)

            Text {
                text: netRow.net ? netRow.net.ssid : ""
                font.pixelSize: Math.round(13 * localScale)
                font.weight: netRow.isCurrent ? Font.Medium : Font.Normal
                color: netRow.isCurrent ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                width: Math.round(170 * localScale)
                elide: Text.ElideRight
            }

            Text {
                visible: netRow.needsPassword && !netRow.isCurrent
                text: "Password required"
                font.pixelSize: Math.round(10 * localScale)
                color: Qt.rgba(245/255, 196/255, 122/255, 0.80)
            }

            Text {
                visible: netRow.isCurrent
                text: NetworkService.connectivity === "portal"
                    ? "Action Needed"
                    : (NetworkService.connectivity === "none" || NetworkService.connectivity === "limited")
                        ? "No Internet"
                        : "Connected"
                font.pixelSize: Math.round(10 * localScale)
                color: NetworkService.connectivity === "full" ? Theme.active : Qt.rgba(245/255, 196/255, 122/255, 1.0)
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
            spacing: Math.round(6 * localScale)

            Text {
                visible: netRow.net ? (netRow.net.secured && !netRow.isCurrent) : false
                text: "󰌾"
                font.pixelSize: Math.round(11 * localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.28)
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Math.round(22 * localScale)
                height: Math.round(16 * localScale)
                anchors.verticalCenter: parent.verticalCenter
                SignalBars {
                    anchors.centerIn: parent
                    signal: netRow.net ? netRow.net.signal : 0
                    localScale: netRow.localScale
                }
            }

            Item {
                visible: netRow.isConnecting
                width: Math.round(20 * localScale)
                height: Math.round(20 * localScale)
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "○"
                    font.pixelSize: Math.round(14 * localScale)
                    color: Theme.active
                    SequentialAnimation on opacity {
                        running: netRow.isConnecting
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: Anim.verySlow }
                        NumberAnimation { to: 1.0; duration: Anim.verySlow }
                    }
                }
            }

            // Disconnect
            Item {
                visible: netRow.isCurrent
                width: Math.round(28 * localScale)
                height: Math.round(28 * localScale)
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(6 * localScale)
                    color: dH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰖪"
                    font.pixelSize: Math.round(14 * localScale)
                    color: dH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }
                HoverHandler { id: dH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: netRow.disconnectClicked()
                }
            }

            // Forget
            Item {
                visible: netRow.isCurrent
                width: Math.round(28 * localScale)
                height: Math.round(28 * localScale)
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(6 * localScale)
                    color: fH.hovered
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                        : netRow.isForgetPending
                            ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.10)
                            : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰗼"
                    font.pixelSize: Math.round(13 * localScale)
                    color: (fH.hovered || netRow.isForgetPending) ? Theme.error : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                }
                HoverHandler { id: fH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: netRow.toggleForget(netRow.net.ssid)
                }
            }

            // Connect
            Rectangle {
                visible: !netRow.isCurrent && !netRow.isConnecting
                anchors.verticalCenter: parent.verticalCenter
                width: connectLbl.implicitWidth + Math.round(20 * localScale)
                height: Math.round(28 * localScale)
                radius: Math.round(8 * localScale)
                color: conH.hovered
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.22)
                    : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.09)
                border.color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                border.width: Math.max(1, Math.round(1 * localScale))
                Behavior on color { ColorAnimation { duration: Anim.fast } }
                Text {
                    id: connectLbl
                    anchors.centerIn: parent
                    text: netRow.isExpanded ? "Retry" : "Connect"
                    font.pixelSize: Math.round(11 * localScale)
                    font.weight: Font.Medium
                    color: Theme.active
                }
                HoverHandler { id: conH; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (netRow.isExpanded && passInput.text !== "")
                            netRow.connectClicked(netRow.net.ssid, passInput.text)
                        else
                            netRow.connectClicked(netRow.net.ssid, "")
                    }
                }
            }
        }
    }

    Item {
        id: expandArea
        anchors { top: baseRow.bottom; left: parent.left; right: parent.right }
        clip: true
        height: netRow.isForgetPending
            ? forgetRow.implicitHeight + Math.round(16 * localScale)
            : netRow.isExpanded
                ? passRow.implicitHeight + Math.round(16 * localScale)
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

        Item {
            id: forgetRow
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
            implicitHeight: Math.round(32 * localScale)
            opacity: netRow.isForgetPending ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.mediumFast } }

            Rectangle {
                anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                radius: Math.round(8 * localScale)
                color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.07)
                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22)
                border.width: Math.max(1, Math.round(1 * localScale))

                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(12 * localScale)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Forget this network?"
                        font.pixelSize: Math.round(11 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
                    }

                    Rectangle {
                        width: Math.round(54 * localScale)
                        height: Math.round(24 * localScale)
                        radius: Math.round(6 * localScale)
                        color: cfH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: Math.round(10 * localScale)
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                        }
                        HoverHandler { id: cfH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: netRow.cancelForget()
                        }
                    }

                    Rectangle {
                        width: Math.round(54 * localScale)
                        height: Math.round(24 * localScale)
                        radius: Math.round(6 * localScale)
                        color: ffH.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.35) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18)
                        Behavior on color { ColorAnimation { duration: Anim.superFast } }
                        Text {
                            anchors.centerIn: parent
                            text: "Forget"
                            font.pixelSize: Math.round(10 * localScale)
                            font.weight: Font.Medium
                            color: Theme.error
                        }
                        HoverHandler { id: ffH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: netRow.confirmForget(netRow.net.ssid)
                        }
                    }
                }
            }
        }

        Item {
            id: passRow
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Math.round(8 * localScale) }
            implicitHeight: Math.round(40 * localScale)
            opacity: netRow.isExpanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Anim.mediumFast } }

            Row {
                anchors { fill: parent; leftMargin: Math.round(10 * localScale); rightMargin: Math.round(10 * localScale) }
                spacing: Math.round(8 * localScale)

                Rectangle {
                    width: parent.width - parent.spacing
                    height: Math.round(32 * localScale)
                    radius: Math.round(8 * localScale)
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                    border.color: passInput.activeFocus ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
                    border.width: Math.max(1, Math.round(1 * localScale))
                    Behavior on border.color { ColorAnimation { duration: Anim.color } }

                    Text {
                        anchors { left: parent.left; leftMargin: Math.round(10 * localScale); verticalCenter: parent.verticalCenter }
                        text: "Password…"
                        font.pixelSize: Math.round(12 * localScale)
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.22)
                        visible: passInput.text === ""
                    }

                    TextInput {
                        id: passInput
                        anchors {
                            left: parent.left; leftMargin: Math.round(10 * localScale)
                            right: eyeBtn.left; rightMargin: Math.round(6 * localScale)
                            top: parent.top; bottom: parent.bottom
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.pixelSize: Math.round(12 * localScale)
                        echoMode: netRow._showPass ? TextInput.Normal : TextInput.Password
                        selectionColor: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.35)
                        clip: true
                        onActiveFocusChanged: Popups.isInputFocused = activeFocus
                        Keys.onReturnPressed: {
                            if (text.length > 0)
                                netRow.connectClicked(netRow.net.ssid, text)
                        }
                        Keys.onEscapePressed: function(event) {
                            event.accepted = true
                            passInput.text = ""
                            netRow.cancelExpand()
                        }
                    }

                    Item {
                        id: eyeBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: Math.round(28 * localScale)
                        height: Math.round(28 * localScale)
                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(6 * localScale)
                            color: eyeH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: netRow._showPass ? "" : ""
                            font.pixelSize: Math.round(13 * localScale)
                            color: netRow._showPass ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.28)
                        }
                        HoverHandler { id: eyeH; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: netRow._showPass = !netRow._showPass
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible && netRow.isExpanded)
                Qt.callLater(function() { passInput.forceActiveFocus() })
        }
    }

    onIsExpandedChanged: {
        if (isExpanded)
            Qt.callLater(function() { passInput.forceActiveFocus() })
        else
            passInput.text = ""
    }

    HoverHandler { id: rHov; enabled: !netRow.isCurrent }
}
