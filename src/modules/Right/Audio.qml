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
import "../../components"
import Quickshell.Services.Pipewire
import "../../"

Item {
    id: root

    property bool showPercentage: PrefsService.alwaysShowVolumePercentage
    property real localScale: 1.0

    implicitWidth:  row.implicitWidth + Math.round(6 * localScale)
    implicitHeight: row.implicitHeight

    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    readonly property string icon: {
        if (!sink?.ready)            return "󰕾"
        if (sink.audio.muted)        return "󰝟"
        if (sink.audio.volume > 0.6) return "󰕾"
        if (sink.audio.volume > 0.2) return "󰖀"
        return "󰕿"
    }

    readonly property int pct: sink?.ready ? Math.round(sink.audio.volume * 100) : 0

    HoverHandler {
        id: hov
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(3 * localScale)

        Text {
            id: iconText
            text:           root.icon
            color:          hov.hovered ? Theme.active : Theme.text
            font.pixelSize: Math.round(18 * localScale)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        Item {
            id: pctWrapper
            property bool show: root.showPercentage || hov.hovered
            implicitWidth: show ? pctText.implicitWidth + Math.round(2 * localScale) : 0
            implicitHeight: pctText.implicitHeight
            clip: true
            anchors.verticalCenter: parent.verticalCenter
            Behavior on implicitWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod} }
        
            Text {
                id: pctText
                text:           root.pct + "%"
                color:          hov.hovered ? Theme.active : Theme.text
                font.pixelSize: Math.round(12 * localScale)
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Anim.color} }
            }
        }
    }

    MouseArea {
        anchors.fill:        parent
        acceptedButtons:     Qt.LeftButton | Qt.RightButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (root.sink?.ready)
                    root.sink.audio.muted = !root.sink.audio.muted
            } else {
                if (!Popups.audioOpen) {
                    SurfaceState.open("rightCenter", "audio")
                    Popups.audioPinned = true
                } else {
                    SurfaceState.close()
                }
            }
        }
    }
}
