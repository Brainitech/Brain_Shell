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
import Quickshell.Io
import "../../../"

Rectangle {
    id: filterPickerRoot

    property real localScale: 1.0
    property bool isOpen: false

    readonly property string currentFilter: WM.currentScreenShader
    property var    filterList:    []

    property string shaderPaths: WM.defaultShaderPaths

    visible: isOpen
    z: 20

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
        } else if (parent) {
            parent.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: function(event) {
        filterPickerRoot.isOpen = false
        event.accepted = true
    }

    anchors {
        right: parent ? parent.right : undefined
        bottom: parent ? parent.bottom : undefined
        rightMargin: Math.round(12 * localScale)
        bottomMargin: Math.round(12 * localScale)
    }

    width: Math.round(180 * localScale)
    height: Math.min(Math.round(280 * localScale), pickerCol.implicitHeight + Math.round(16 * localScale))
    radius: Math.round(Theme.cornerRadius * localScale)

    color: Qt.rgba(
        Math.min(1, Theme.background.r + 0.05),
        Math.min(1, Theme.background.g + 0.05),
        Math.min(1, Theme.background.b + 0.05),
        0.98)
    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
    border.width: 1

    opacity: filterPickerRoot.isOpen ? 1 : 0
    scale: filterPickerRoot.isOpen ? 1 : 0.95
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

    Process {
        id: filterListProc
        command: ["bash", "-c", "find " + filterPickerRoot.shaderPaths + " -maxdepth 1 -type f \\( -name '*.glsl' -o -name '*.frag' \\) 2>/dev/null | rev | cut -d/ -f1 | rev | sed 's/\\.[^.]*$//' | sort -u"]
        running: false
        stdout: SplitParser {
            onRead: function(l) {
                var n = l.trim()
                if (n !== "") filterPickerRoot.filterList = filterPickerRoot.filterList.concat([n])
            }
        }
    }

    Connections {
        target: WallpaperService
        function onWallpaperApplied(path) {
            WM.checkScreenShader()
        }
    }

    Connections {
        target: Popups
        function onDashboardOpenChanged() {
            if (!Popups.dashboardOpen) filterPickerRoot.isOpen = false
        }
    }

    function applyFilter(name) {
        WM.setScreenShader(name, filterPickerRoot.shaderPaths)
        filterPickerRoot.isOpen = false
    }

    function open() {
        filterPickerRoot.filterList = []
        filterListProc.running = false
        filterListProc.running = true
        filterPickerRoot.isOpen = true
    }

    function close() {
        filterPickerRoot.isOpen = false
    }

    function toggle() {
        if (filterPickerRoot.isOpen) close()
        else open()
    }

    Flickable {
        anchors { fill: parent; margins: Math.round(8 * localScale) }
        contentWidth: width
        contentHeight: pickerCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: pickerCol
            width: parent.width
            spacing: Math.round(2 * localScale)

            Text {
                width: parent.width
                text: "SHADER"
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
                property bool isActive: filterPickerRoot.currentFilter === ""
                color: isActive
                    ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                    : offH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
                Behavior on color { ColorAnimation { duration: Anim.fast } }

                Row {
                    anchors {
                        left: parent.left
                        leftMargin: Math.round(10 * localScale)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Math.round(8 * localScale)

                    Text {
                        text: parent.parent.isActive ? "●" : "○"
                        font.pixelSize: Math.round(9 * localScale)
                        color: parent.parent.isActive ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                    }
                    Text {
                        text: "Off"
                        font.pixelSize: Math.round(12 * localScale)
                        color: parent.parent.isActive ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.fast } }
                    }
                }
                HoverHandler { id: offH; cursorShape: Qt.PointingHandCursor }
                TapHandler   { onTapped: filterPickerRoot.applyFilter("") }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)
            }

            Repeater {
                model: filterPickerRoot.filterList
                delegate: Rectangle {
                    required property string modelData
                    property bool isActive: filterPickerRoot.currentFilter === modelData

                    width: pickerCol.width
                    height: Math.round(28 * localScale)
                    radius: Math.round(6 * localScale)
                    color: isActive
                        ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
                        : itemH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
                    Behavior on color { ColorAnimation { duration: Anim.fast } }

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: Math.round(10 * localScale)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Math.round(8 * localScale)

                        Text {
                            text: parent.parent.isActive ? "●" : "○"
                            font.pixelSize: Math.round(9 * localScale)
                            color: parent.parent.isActive ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.30)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                        }
                        Text {
                            text: modelData
                            font.pixelSize: Math.round(12 * localScale)
                            color: parent.parent.isActive ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.65)
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: pickerCol.width - Math.round(38 * localScale)
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                        }
                    }
                    HoverHandler { id: itemH; cursorShape: Qt.PointingHandCursor }
                    TapHandler   { onTapped: filterPickerRoot.applyFilter(modelData) }
                }
            }

            Text {
                width: parent.width
                visible: filterPickerRoot.filterList.length === 0
                text: "Loading…"
                font.pixelSize: Math.round(11 * localScale)
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)
                horizontalAlignment: Text.AlignHCenter
                topPadding: Math.round(4 * localScale)
            }
        }
    }

    Component.onCompleted: {
        WM.checkScreenShader()
    }
}
