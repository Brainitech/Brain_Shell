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
import "sliders"

Item {
    id: root
    property real localScale: 1.0
    property string text: "Slider Option"
    property string description: ""
    property real value: 0.5
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.1
    property bool showValue: true
    property string valueSuffix: ""
    property var formatValue: function(v) { 
        if (valueSuffix === "ms") {
            if (v >= 1000) return (v / 1000).toString() + "s"
            return v.toString() + "ms"
        }
        return (Math.round(v * 10) / 10).toString() + valueSuffix
    }
    
    property var defaultValue: undefined
    readonly property bool _hasDefault: defaultValue !== undefined
    readonly property bool _isDefault: _hasDefault && Math.abs(value - defaultValue) < 0.001

    width: parent ? parent.width : 400
    height: Math.round(description !== "" ? (44 * localScale) : (32 * localScale))

    Column {
        anchors {
            left: parent.left
            right: sliderArea.left
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

    Item {
        id: sliderArea
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: Math.round(160 * localScale)
        height: Math.round(24 * localScale)

        HorizontalSliderTrack {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: root.showValue ? (parent.width - Math.round(50 * localScale)) : parent.width
            height: Math.round(24 * localScale)
            localScale: root.localScale
            value: {
                var range = root.to - root.from
                return range > 0 ? Math.max(0.0, Math.min(1.0, (root.value - root.from) / range)) : 0.0
            }
            accent: Theme.active
            onValueMoved: function(normVal) {
                var range = root.to - root.from
                var rawVal = root.from + (normVal * range)
                var steps = Math.round(rawVal / root.stepSize)
                var snapped = Math.max(root.from, Math.min(root.to, steps * root.stepSize))
                if (snapped !== root.value) {
                    root.value = snapped
                }
            }
        }

        Rectangle {
            id: rstBtn
            visible: root._hasDefault && !root._isDefault
            width: Math.round(20 * localScale)
            height: Math.round(20 * localScale)
            radius: Math.round(6 * localScale)
            anchors { right: sliderArea.left; rightMargin: Math.round(8 * localScale); verticalCenter: parent.verticalCenter }
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
                onClicked: root.value = root.defaultValue
            }
        }

        Text {
            id: valText
            visible: root.showValue
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: root.formatValue(root.value)
            color: Theme.subtext
            font.pixelSize: Math.round(12 * localScale)
            horizontalAlignment: Text.AlignRight
            width: Math.round(45 * localScale)
        }
    }
}
