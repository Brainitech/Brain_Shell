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
import Quickshell.Services.Pipewire
import "../../"

Item {
    id: sliderRoot

    property real localScale: 1.0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: (sliderRoot.sink && sliderRoot.sink.ready) || false
    readonly property real volume: (sliderRoot.ready && sliderRoot.sink.audio) ? sliderRoot.sink.audio.volume : 0.0
    readonly property bool muted: (sliderRoot.ready && sliderRoot.sink.audio) ? sliderRoot.sink.audio.muted : false

    PwObjectTracker {
        objects: sliderRoot.sink ? [sliderRoot.sink] : []
    }

    implicitWidth: parent ? parent.width : 300
    implicitHeight: Math.round(52 * sliderRoot.localScale)
    width: parent ? parent.width : implicitWidth
    height: implicitHeight

    Text {
        id: volLbl
        anchors {
            left: parent.left
            top: parent.top
        }
        text: "VOLUME"
        font.pixelSize: Math.round(9 * sliderRoot.localScale)
        font.weight: Font.Bold
        color: sliderRoot.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.55)
    }

    Text {
        id: volValText
        anchors {
            right: parent.right
            top: parent.top
        }
        text: !sliderRoot.ready ? "--%" : (sliderRoot.muted ? "MUTED" : Math.round(sliderRoot.volume * 100) + "%")
        font.pixelSize: Math.round(9 * sliderRoot.localScale)
        font.family: "JetBrains Mono"
        font.weight: Font.Bold
        color: sliderRoot.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.7)
    }

    Row {
        id: sliderRow
        anchors {
            left: parent.left
            right: parent.right
            top: volLbl.bottom
            topMargin: Math.round(8 * sliderRoot.localScale)
        }
        spacing: Math.round(8 * sliderRoot.localScale)

        Item {
            id: minIconBox
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(13 * sliderRoot.localScale)
            height: Math.round(13 * sliderRoot.localScale)

            Text {
                id: minIcon
                anchors.centerIn: parent
                text: {
                    if (!sliderRoot.ready) return "󰕾"
                    if (sliderRoot.muted) return "󰖁"
                    if (sliderRoot.volume > 0.6) return "󰕾"
                    if (sliderRoot.volume > 0.2) return "󰖀"
                    return "󰕿"
                }
                font.pixelSize: Math.round(13 * sliderRoot.localScale)
                color: sliderRoot.muted
                    ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
                    : (sliderRoot.volume > 0 ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35))
            }

            MouseArea {
                id: muteTap
                anchors.fill: parent
                anchors.margins: -Math.round(4 * sliderRoot.localScale)
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (sliderRoot.ready && sliderRoot.sink.audio) {
                        sliderRoot.sink.audio.muted = !sliderRoot.sink.audio.muted
                    }
                }
            }
        }

        HorizontalSliderTrack {
            id: btw
            width: Math.max(0, parent.width - Math.round(13 * sliderRoot.localScale) * 2 - sliderRow.spacing * 2)
            height: Math.round(30 * sliderRoot.localScale)
            anchors.verticalCenter: parent.verticalCenter
            localScale: sliderRoot.localScale
            value: Math.min(1.0, sliderRoot.volume)
            muted: sliderRoot.muted
            accent: Theme.active
            onValueMoved: function(v) {
                if (sliderRoot.ready && sliderRoot.sink.audio) {
                    sliderRoot.sink.audio.volume = v
                    if (sliderRoot.sink.audio.muted)
                        sliderRoot.sink.audio.muted = false
                }
            }
        }

        Text {
            id: maxIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "󰕾"
            font.pixelSize: Math.round(13 * sliderRoot.localScale)
            color: sliderRoot.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) : Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.75)
        }
    }
}
