import QtQuick
import Quickshell.Services.Pipewire
import "../../components"
import "../../"

Item {
    id: root

    property bool showPercentage: false
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
            Behavior on implicitWidth { NumberAnimation { duration: Anim.transition; easing.type: Anim.inOutCubic} }
        
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
