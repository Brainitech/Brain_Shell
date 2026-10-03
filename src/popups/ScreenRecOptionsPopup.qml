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
import "../theme"
import "../state"
import "../services"
import "../components"
import "../"

Item {
    id: root
    property real localScale: 1.0

    // Metrics
    readonly property int gap: Math.round(8 * localScale)
    
    width: ScreenRecService.popupTargetWidth > 0 ? ScreenRecService.popupTargetWidth : Math.round(340 * localScale)
    
    readonly property int tileW: Math.floor((width - (gap * 2) - Math.round(16 * localScale) - (gap * 2)) / 3)
    readonly property int targetTileH: Math.round(54 * localScale)
    readonly property int audioFpsTileH: Math.round(42 * localScale)
    
    readonly property int targetCardH: targetTileH + Math.round(16 * localScale)
    readonly property int bottomCardH: (audioFpsTileH * 2) + gap + Math.round(16 * localScale)
    readonly property int backendCardH: audioFpsTileH + Math.round(16 * localScale)

    height: targetCardH + gap + bottomCardH + gap + backendCardH

    property bool isOpen: ScreenRecService.optionsExpanded && !ScreenRecService.recording
    opacity: isOpen ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }

    property real expandOffset: opacity === 1 ? 0 : -Math.round(20 * localScale)
    Behavior on expandOffset { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic; easing.overshoot: Anim.globalOvershoot; easing.amplitude: Anim.globalAmplitude; easing.period: Anim.globalPeriod } }

    function withAlpha(col, a) {
        if (!col) return "transparent";
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: root.gap
        anchors.rightMargin: root.gap
        transform: Translate { y: root.expandOffset }

        MouseArea { anchors.fill: parent }
        HoverHandler {
            onHoveredChanged: {
                if (hovered) ScreenRecService.keepExpanded()
                else ScreenRecService.scheduleClose()
            }
        }

        // Target Card
        StatCard {
            id: targetCard
            localScale: root.localScale
            padding: root.gap
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.targetCardH

            Row {
                anchors.centerIn: parent
                spacing: root.gap

                TglBtn { width: root.tileW; height: root.targetTileH; icon: "󰍹"; label: "Screen"; on: PrefsService.screenrecCaptureTarget === "screen"; onToggled: PrefsService.screenrecCaptureTarget = "screen" }
                TglBtn { width: root.tileW; height: root.targetTileH; icon: "󱂬"; label: "Window"; on: PrefsService.screenrecCaptureTarget === "window"; onToggled: PrefsService.screenrecCaptureTarget = "window" }
                TglBtn { width: root.tileW; height: root.targetTileH; icon: "󰩭"; label: "Region"; on: PrefsService.screenrecCaptureTarget === "region"; onToggled: PrefsService.screenrecCaptureTarget = "region" }
            }
        }

        // Audio Card
        StatCard {
            id: audioCard
            localScale: root.localScale
            padding: root.gap
            anchors.top: targetCard.bottom; anchors.topMargin: root.gap
            anchors.left: parent.left
            height: root.bottomCardH
            width: (parent.width - root.gap) / 2

            Column {
                anchors.centerIn: parent
                width: parent.width - Math.round(16 * localScale)
                spacing: root.gap

                TglBtn { width: parent.width; height: root.audioFpsTileH; layoutMode: "horizontal"; icon: "󰍬"; label: "Mic"; on: PrefsService.screenrecAudioMic; onToggled: PrefsService.screenrecAudioMic = !PrefsService.screenrecAudioMic }
                TglBtn { width: parent.width; height: root.audioFpsTileH; layoutMode: "horizontal"; icon: "󰓃"; label: "System"; on: PrefsService.screenrecAudioSystem; onToggled: PrefsService.screenrecAudioSystem = !PrefsService.screenrecAudioSystem }
            }
        }

        // FPS Card
        StatCard {
            id: fpsCard
            localScale: root.localScale
            padding: root.gap
            anchors.top: targetCard.bottom; anchors.topMargin: root.gap
            anchors.right: parent.right
            height: root.bottomCardH
            width: (parent.width - root.gap) / 2

            Column {
                anchors.centerIn: parent
                width: parent.width - Math.round(16 * localScale)
                spacing: root.gap

                TglBtn { width: parent.width; height: root.audioFpsTileH; label: "60 FPS"; on: PrefsService.screenrecFramerate === 60; onToggled: PrefsService.screenrecFramerate = 60 }
                TglBtn { width: parent.width; height: root.audioFpsTileH; label: "30 FPS"; on: PrefsService.screenrecFramerate === 30; onToggled: PrefsService.screenrecFramerate = 30 }
            }
        }

        // Backend Card
        StatCard {
            id: backendCard
            localScale: root.localScale
            padding: root.gap
            anchors.top: audioCard.bottom; anchors.topMargin: root.gap
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.backendCardH

            Row {
                anchors.centerIn: parent
                spacing: root.gap

                Repeater {
                    model: ScreenRecService.backends
                    delegate: TglBtn {
                        required property var modelData
                        width: root.tileW
                        height: root.audioFpsTileH
                        label: modelData.label
                        labelSize: 10
                        available: ScreenRecService.backendAvailable[modelData.id] !== false
                        on: PrefsService.screenrecBackend === modelData.id
                        onToggled: PrefsService.screenrecBackend = modelData.id
                    }
                }
            }
        }
    }

    component TglBtn: Rectangle {
        id: btn
        property bool on: false
        property string icon: ""
        property string label: ""
        property string layoutMode: "vertical"
        property int labelSize: 11
        property bool available: true
        signal toggled()

        radius: Math.round(10 * localScale)
        opacity: available ? 1.0 : 0.4
        Behavior on opacity { NumberAnimation { duration: Anim.fast } }
        color: on
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.14)
            : bH.hovered
                ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
        border.color: on
            ? Qt.rgba(Theme.active.r, Theme.active.g, Theme.active.b, 0.30)
            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
        border.width: 1
        Behavior on color        { ColorAnimation { duration: Anim.color} }
        Behavior on border.color { ColorAnimation { duration: Anim.color} }

        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: Math.round(8 * localScale) }
            width: Math.round(6 * localScale); height: Math.round(6 * localScale); radius: width / 2
            color: btn.on ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18)
            Behavior on color { ColorAnimation { duration: Anim.color} }
        }

        Item {
            anchors.fill: parent
            
            //Target tiles
            Column {
                visible: btn.icon !== "" && btn.layoutMode === "vertical"
                anchors.centerIn: parent
                spacing: Math.round(4 * localScale)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btn.icon; font.pixelSize: Math.round(15 * localScale)
                    color: btn.on ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.40)
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btn.label; font.pixelSize: Math.round(10 * localScale); font.weight: Font.Medium
                    color: btn.on ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                }
            }

            // Audio tiles
            Row {
                visible: btn.icon !== "" && btn.layoutMode === "horizontal"
                anchors.centerIn: parent
                spacing: Math.round(8 * localScale)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.icon; font.pixelSize: Math.round(15 * localScale)
                    color: btn.on ? Theme.active : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.40)
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btn.label; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
                    color: btn.on ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                    Behavior on color { ColorAnimation { duration: Anim.color} }
                }
            }

            // FPS / backend tiles — margins keep the label clear of the status
            // dot in the top-right corner, which longer names used to run under.
            Text {
                visible: btn.icon === ""
                anchors.fill: parent
                anchors.leftMargin:  Math.round(8 * localScale)
                anchors.rightMargin: Math.round(8 * localScale)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                elide: Text.ElideRight
                text: btn.label; font.pixelSize: Math.round(btn.labelSize * localScale); font.weight: Font.Medium
                color: btn.on ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.45)
                Behavior on color { ColorAnimation { duration: Anim.color} }
            }
        }

        HoverHandler { id: bH; cursorShape: Qt.PointingHandCursor }
        MouseArea { 
            anchors.fill: parent
            onClicked: btn.toggled()
        }
    }
}
