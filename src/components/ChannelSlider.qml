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
import "../"

Item {
    id: root
    property real localScale: 1.0
    property string label: ""
    property string icon: ""
    property real value: 0.0
    property bool muted: false
    property bool active: false
    property color accent: Theme.active

    signal volumeChanged(real value)
    signal muteToggled()

    implicitWidth: loader.item ? Math.max(Math.round(56 * localScale), loader.item.implicitWidth) : Math.round(56 * localScale)
    implicitHeight: loader.item ? loader.item.implicitHeight : Math.round(260 * localScale)
    width: implicitWidth
    height: implicitHeight

    Loader {
        id: loader
        anchors.centerIn: parent
        source: {
            switch (PrefsService.sliderStyle) {
                case "glow":
                case "modern": return Qt.resolvedUrl("sliders/channel_styles/GlowSliderStyle.qml")
                case "outline":
                case "concentric": return Qt.resolvedUrl("sliders/channel_styles/OutlineSliderStyle.qml")
                case "ring":
                case "floating": return Qt.resolvedUrl("sliders/channel_styles/RingSliderStyle.qml")
                case "dynamic":
                case "expanding": return Qt.resolvedUrl("sliders/channel_styles/DynamicSliderStyle.qml")
                case "segmented":
                case "futuristic": return Qt.resolvedUrl("sliders/channel_styles/SegmentedSliderStyle.qml")
                case "capsule":
                case "classic":
                default:
                    return Qt.resolvedUrl("sliders/channel_styles/CapsuleSliderStyle.qml")
            }
        }
    }

    Binding { target: loader.item; property: "localScale"; value: root.localScale }
    Binding { target: loader.item; property: "label"; value: root.label }
    Binding { target: loader.item; property: "icon"; value: root.icon }
    Binding { target: loader.item; property: "value"; value: root.value }
    Binding { target: loader.item; property: "muted"; value: root.muted }
    Binding { target: loader.item; property: "active"; value: root.active }
    Binding { target: loader.item; property: "accent"; value: root.accent }

    Connections {
        target: loader.item
        function onVolumeChanged(v) { root.volumeChanged(v) }
        function onMuteToggled() { root.muteToggled() }
    }
}
