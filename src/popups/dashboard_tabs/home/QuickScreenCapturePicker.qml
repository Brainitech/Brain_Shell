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
import Quickshell
import "../../../"

Rectangle {
    id: capturePickerRoot

    property real localScale: 1.0
    property bool isOpen: false

    visible: isOpen
    z: 20

    onVisibleChanged: {
        if (visible) forceActiveFocus()
        else if (parent) parent.forceActiveFocus()
    }

    Keys.onEscapePressed: function(event) {
        capturePickerRoot.isOpen = false
        event.accepted = true
    }

    anchors {
        right: parent ? parent.right : undefined
        bottom: parent ? parent.bottom : undefined
        rightMargin: Math.round(12 * localScale)
        bottomMargin: Math.round(12 * localScale)
    }

    width: Math.round(180 * localScale)
    height: captureCol.implicitHeight + Math.round(16 * localScale)
    radius: Math.round(Theme.cornerRadius * localScale)

    color: Qt.rgba(
        Math.min(1, Theme.background.r + 0.05),
        Math.min(1, Theme.background.g + 0.05),
        Math.min(1, Theme.background.b + 0.05),
        0.98)
    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
    border.width: 1

    opacity: capturePickerRoot.isOpen ? 1 : 0
    scale: capturePickerRoot.isOpen ? 1 : 0.95
    Behavior on opacity {
        NumberAnimation {
            duration: Anim.color
            easing.type: Anim.outCubic
            easing.overshoot: Anim.globalOvershoot
            easing.amplitude: Anim.globalAmplitude
            easing.period: Anim.globalPeriod
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Anim.color
            easing.type: Anim.outCubic
            easing.overshoot: Anim.globalOvershoot
            easing.amplitude: Anim.globalAmplitude
            easing.period: Anim.globalPeriod
        }
    }
    transformOrigin: Item.BottomRight

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (!Popups.dashboardOpen) capturePickerRoot.isOpen = false
        }
    }

    function open() {
        capturePickerRoot.isOpen = true
    }

    function close() {
        capturePickerRoot.isOpen = false
    }

    function toggle() {
        capturePickerRoot.isOpen = !capturePickerRoot.isOpen
    }

    Item {
        anchors { fill: parent; margins: Math.round(8 * localScale) }

        Column {
            id: captureCol
            width: parent.width
            spacing: Math.round(2 * localScale)

            Text {
                width: parent.width
                text: "CAPTURE"
                font.pixelSize: Math.round(9 * localScale)
                font.weight: Font.Bold
                color: Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
                leftPadding: Math.round(4 * localScale)
                bottomPadding: Math.round(4 * localScale)
            }

            Rectangle {
                width: parent.width
                height: Math.round(28 * localScale)
                radius: Math.round(6 * localScale)
                color: shotH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Math.round(8 * localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Screenshot"
                    color: Theme.text
                    font.pixelSize: Math.round(11 * localScale)
                }
                HoverHandler { id: shotH; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        capturePickerRoot.isOpen = false
                        IpcManager.screenshotDelayed()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Math.round(28 * localScale)
                radius: Math.round(6 * localScale)
                color: recH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: Math.round(8 * localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Screen Record"
                    color: Theme.text
                    font.pixelSize: Math.round(11 * localScale)
                }
                HoverHandler { id: recH; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        capturePickerRoot.isOpen = false
                        Popups.closeAll()
                        ShellState.screenRecord = true
                    }
                }
            }
        }
    }
}
