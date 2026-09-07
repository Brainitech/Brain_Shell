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
    
    readonly property int tileW: Math.floor((width - Math.round(16 * localScale) - (gap * 2)) / 3) // 16px is 8px left + 8px right padding on StatCard
    readonly property int targetTileH: Math.round(54 * localScale)
    readonly property int audioFpsTileH: Math.round(42 * localScale)
    
    readonly property int targetCardH: targetTileH + Math.round(16 * localScale)
    readonly property int bottomCardH: (audioFpsTileH * 2) + gap + Math.round(16 * localScale)

    height: targetCardH + gap + bottomCardH

    property bool isOpen: ScreenRecService.optionsExpanded && !ScreenRecService.recording
    opacity: isOpen ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic } }

    property real expandOffset: opacity === 1 ? 0 : -Math.round(20 * localScale)
    Behavior on expandOffset { NumberAnimation { duration: Anim.mediumFast; easing.type: Anim.outCubic } }

    function withAlpha(col, a) {
        if (!col) return "transparent";
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    Item {
        anchors.fill: parent
        transform: Translate { y: root.expandOffset }

        MouseArea { anchors.fill: parent }

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
            anchors.bottom: parent.bottom
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
            anchors.bottom: parent.bottom
            width: (parent.width - root.gap) / 2

            Column {
                anchors.centerIn: parent
                width: parent.width - Math.round(16 * localScale)
                spacing: root.gap

                TglBtn { width: parent.width; height: root.audioFpsTileH; label: "60 FPS"; on: PrefsService.screenrecFramerate === 60; onToggled: PrefsService.screenrecFramerate = 60 }
                TglBtn { width: parent.width; height: root.audioFpsTileH; label: "30 FPS"; on: PrefsService.screenrecFramerate === 30; onToggled: PrefsService.screenrecFramerate = 30 }
            }
        }
    }

    component TglBtn: Rectangle {
        id: btn
        property bool on: false
        property string icon: ""
        property string label: ""
        property string layoutMode: "vertical"
        signal toggled()

        radius: Math.round(10 * localScale)
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

            // FPS tiles
            Text {
                visible: btn.icon === ""
                anchors.centerIn: parent
                text: btn.label; font.pixelSize: Math.round(11 * localScale); font.weight: Font.Medium
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
