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
    id: root
    property real localScale: 1.0
    property real value: 0.0
    property color accent: Theme.active
    property bool active: true
    property bool muted: false
    property bool interactive: true

    signal valueMoved(real value)
    signal valueCommitted(real value)

    implicitWidth: Math.round(160 * localScale)
    implicitHeight: Math.round(24 * localScale)

    Loader {
        id: loader
        anchors.fill: parent
        source: {
            switch (PrefsService.sliderStyle) {
                case "glow":
                case "modern":
                    return Qt.resolvedUrl("horizontal_styles/HorizontalGlowStyle.qml")
                case "outline":
                case "concentric":
                    return Qt.resolvedUrl("horizontal_styles/HorizontalOutlineStyle.qml")
                case "ring":
                case "floating":
                    return Qt.resolvedUrl("horizontal_styles/HorizontalRingStyle.qml")
                case "dynamic":
                case "expanding":
                    return Qt.resolvedUrl("horizontal_styles/HorizontalDynamicStyle.qml")
                case "segmented":
                case "futuristic":
                    return Qt.resolvedUrl("horizontal_styles/HorizontalSegmentedStyle.qml")
                case "capsule":
                case "classic":
                default:
                    return Qt.resolvedUrl("horizontal_styles/HorizontalCapsuleStyle.qml")
            }
        }
    }

    Binding { target: loader.item; property: "localScale"; value: root.localScale }
    Binding { target: loader.item; property: "value"; value: root.value }
    Binding { target: loader.item; property: "accent"; value: root.accent }
    Binding { target: loader.item; property: "active"; value: root.active }
    Binding { target: loader.item; property: "muted"; value: root.muted }
    Binding { target: loader.item; property: "hovered"; value: hov.hovered }
    Binding { target: loader.item; property: "pressed"; value: dragArea.pressed }

    HoverHandler {
        id: hov
        enabled: root.interactive
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.topMargin: -Math.round(4 * root.localScale)
        anchors.bottomMargin: -Math.round(4 * root.localScale)
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.interactive

        function _calc(mx) {
            return Math.max(0.0, Math.min(1.0, mx / root.width))
        }

        onPressed: {
            var v = _calc(mouseX)
            root.valueMoved(v)
        }
        onPositionChanged: {
            if (pressed) {
                var v = _calc(mouseX)
                root.valueMoved(v)
            }
        }
        onReleased: {
            root.valueCommitted(root.value)
        }
    }

    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(e) {
            var step = e.angleDelta.y > 0 ? 0.05 : -0.05
            var v = Math.max(0.0, Math.min(1.0, root.value + step))
            root.valueMoved(v)
            root.valueCommitted(v)
        }
    }
}
