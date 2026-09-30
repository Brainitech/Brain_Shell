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
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Toggle Option"
    property string description: ""
    property bool checked: false
    
    property var defaultValue: undefined
    property bool useOverrideReset: false
    property bool overrideResetVisible: false
    readonly property bool _hasDefault: defaultValue !== undefined
    readonly property bool _isDefault: _hasDefault && checked === defaultValue
    readonly property bool _showReset: useOverrideReset ? overrideResetVisible : (_hasDefault && !_isDefault)
    
    signal toggled()
    signal resetTriggered()

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (52 * localScale) : (40 * localScale))



    HoverHandler {
        id: toggleMouse
    }

    Column {
        anchors {
            left: parent.left
            leftMargin: Math.round(8 * localScale)
            right: switchRect.left
            rightMargin: Math.round(12 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(4 * localScale)

        Text {
            text: root.text
            color: Theme.text
            font.pixelSize: Math.round(13 * localScale)
        }

        Text {
            visible: root.description !== ""
            text: root.description
            color: Theme.subtext
            font.pixelSize: Math.round(11 * localScale)
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    // Switch Track
    Rectangle {
        id: switchRect
        anchors {
            right: parent.right
            rightMargin: Math.round(8 * localScale)
            verticalCenter: parent.verticalCenter
        }
        width: Math.round(40 * localScale)
        height: Math.round(22 * localScale)
        radius: height / 2
        
        color: root.checked ? (switchHover.hovered ? Qt.lighter(Theme.active, 1.1) : Theme.active) : (switchHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1))
        Behavior on color { ColorAnimation { duration: Anim.fast; easing.type: Anim.linear } }
        
        border.color: root.checked ? Qt.darker(Theme.active, 1.2) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
        border.width: Math.max(1, Math.round(1 * localScale))

        HoverHandler { id: switchHover; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.checked = !root.checked
                root.toggled()
            }
        }

        // Switch Handle
        Rectangle {
            width: Math.round(16 * localScale)
            height: Math.round(16 * localScale)
            radius: width / 2
            
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? (parent.width - width - Math.round(3 * localScale)) : Math.round(3 * localScale)
            
            Behavior on x { NumberAnimation { duration: Anim.fast; easing.type: Anim.globalCurve; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }

            color: "white"
        }
    }

    // Reset to default
    Rectangle {
        id: rstBtn
        visible: root._showReset
        width: Math.round(22 * localScale)
        height: Math.round(22 * localScale)
        radius: Math.round(6 * localScale)
        anchors { right: switchRect.left; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
        color: rstH.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09) : "transparent"
        Behavior on color { ColorAnimation { duration: Anim.fast } }
        
        Text { 
            anchors.centerIn: parent
            text: "↺"
            font.pixelSize: Math.round(13 * localScale)
            color: rstH.hovered ? Theme.active : Theme.subtext 
        }
        
        HoverHandler { id: rstH; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.useOverrideReset) {
                    root.resetTriggered()
                } else {
                    root.checked = root.defaultValue
                    root.toggled()
                }
            }
        }
    }
}
