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
import "../components"
import "../services"
import "../"

Item {
    id: root

    property real localScale: 1.0

    readonly property int popupHeight: Math.round(340 * root.localScale)
    readonly property int popupWidth:  Math.round(180 * root.localScale)

    onOpacityChanged: if (opacity === 1) forceActiveFocus()
    Keys.onEscapePressed: SurfaceState.close()

    MouseArea {
        anchors.fill: parent
        onClicked: Popups.quickPinned = true
    }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property real _bVal: BrightnessService.brightness / 100






    Item {
        id: slide
        anchors.fill: parent
        clip: true
        

        Row {
            anchors.centerIn: parent
            spacing: Math.round(8 * root.localScale)
            
            ChannelSlider {
                localScale: root.localScale
                icon: {
                    if (!root.sink?.ready)            return "󰕾"
                    if (root.sink.audio.muted)        return "󰖁"
                    if (root.sink.audio.volume > 0.6) return "󰕾"
                    if (root.sink.audio.volume > 0.2) return "󰖀"
                    return "󰕿"
                }
                value:  root.sink?.ready ? root.sink.audio.volume : 0
                muted:  root.sink?.audio.muted ?? false
                active: root.sink?.ready ?? false
                onVolumeChanged: function(v) {
                    if (root.sink?.ready) root.sink.audio.volume = v
                }
                onMuteToggled: {
                    if (root.sink?.ready) root.sink.audio.muted = !root.sink.audio.muted
                }
            }

            ChannelSlider {
                localScale: root.localScale
                icon:   "󰃠"
                value:  root._bVal
                muted:  false
                active: true
                onVolumeChanged: function(v) {
                    BrightnessService.setBrightness(Math.round(v * 100))
                }
            }
        }
    }

}
