import QtQuick
import Quickshell
import "../../"
import "../../theme"
import "../../services"
import "../../state"

Item {
    id: delegateRoot
    required property string itemType
    required property real localScale
    required property int fw

    anchors {
        fill: parent
        leftMargin: fw / 2
        rightMargin: fw / 2
    }
    visible: itemType === "record_active"

    // Left: dot + timer, anchored left
    Row {
        anchors {
            left:           parent.left
            leftMargin:     Math.round(10 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: Math.round(7 * localScale)

        // Pulsing red dot
        Rectangle {
            width:  Math.round(8 * localScale); height: Math.round(8 * localScale); radius: Math.round(4 * localScale)
            color:  "#ff4444"
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: ScreenRecService.recording
                loops:   Animation.Infinite
                NumberAnimation { to: 0.25; duration: Anim.extraSlow; easing.type: Anim.inOutSine}
                NumberAnimation { to: 1.0;  duration: Anim.extraSlow; easing.type: Anim.inOutSine}
            }
        }

        // Elapsed time
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           ScreenRecService.elapsedDisplay
            font.pixelSize: Math.round(13 * localScale); font.weight: Font.Bold
            font.family:    "JetBrains Mono"
            color:          Theme.text
        }
    }

    // Center: cava
    Item {
        id: recCava
        anchors.centerIn: parent
        width:  Math.round(44 * localScale)
        height: Math.round(20 * localScale)

        readonly property real _bw:   Math.round(4 * localScale)
        readonly property real _sp:   Math.max(1, (width - _bw * 12) / 5)
        readonly property real _maxH: height / 2

        Row {
            anchors.fill: parent
            spacing:      recCava._sp

            Repeater {
                model: ScreenRecService.audioBars
                delegate: Item {
                    required property int modelData
                    width:  recCava._bw
                    height: recCava.height
                    readonly property real _amp: modelData / 100.0
                    Rectangle {
                        anchors.centerIn: parent
                        width:  recCava._bw
                        height: Math.max(2, _amp * recCava._maxH * 2)
                        radius: width / 2
                        color: PrefsService.screenrecAudioMic || PrefsService.screenrecAudioSystem
                        ? Qt.rgba(0.95, 0.3, 0.3, 0.30 + _amp * 0.70)
                        : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
                        Behavior on height {
                            NumberAnimation { duration: Anim.superFast; easing.type: Anim.outCubic}
                        }
                    }
                }
            }
        }
    }

    // Right: trash + stop, anchored right
    Row {
        anchors {
            right:          parent.right
            rightMargin:    Math.round(10 * localScale)
            verticalCenter: parent.verticalCenter
        }
        spacing: fw / 2

        // Discard button
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(5 * localScale)
            color: recDiscardH.hovered
            ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12)
            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
            Behavior on color { ColorAnimation { duration: Anim.fast} }
            Text {
                anchors.centerIn: parent
                text:           "󰩺"
                font.pixelSize: Math.round(11 * localScale)
                color:          recDiscardH.hovered
                ? Qt.rgba(1, 0.4, 0.4, 1.0)
                : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                Behavior on color { ColorAnimation { duration: Anim.fast} }
            }
            HoverHandler { id: recDiscardH }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.discardRecording() }
        }

        // Stop button
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(22 * localScale); height: Math.round(22 * localScale); radius: Math.round(5 * localScale)
            color: recStopH.hovered
            ? Qt.rgba(0.9, 0.2, 0.2, 0.55)
            : Qt.rgba(0.8, 0.1, 0.1, 0.32)
            Behavior on color { ColorAnimation { duration: Anim.fast} }
            Text {
                anchors.centerIn: parent
                text:           "⏹"
                font.pixelSize: Math.round(10 * localScale)
                color:          "#ff9999"
            }
            HoverHandler { id: recStopH }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ScreenRecService.stopRecording() }
        }
    }
}
